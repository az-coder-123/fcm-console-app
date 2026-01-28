import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../core/constants.dart';
import '../models/notification_history.dart';
import '../models/service_account.dart';

/// Service for Firebase Cloud Messaging operations
/// Handles authentication and sending notifications via FCM v1 HTTP API
class FCMService {
  final Logger _logger = Logger();

  /// Authenticate with Google API using Service Account JSON
  Future<AutoRefreshingAuthClient> authenticate(
    String serviceAccountPath,
  ) async {
    try {
      final file = File(serviceAccountPath);
      final jsonString = await file.readAsString();
      final credentials = ServiceAccountCredentials.fromJson(jsonString);

      final client = await clientViaServiceAccount(credentials, [
        'https://www.googleapis.com/auth/firebase.messaging',
      ]);

      _logger.i('Successfully authenticated with Google API');
      return client;
    } catch (e) {
      _logger.e('Authentication failed: $e');
      rethrow;
    }
  }

  /// Extract project ID from Service Account JSON
  Future<String> getProjectId(String serviceAccountPath) async {
    try {
      final file = File(serviceAccountPath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);
      final projectId = data['project_id'];

      if (projectId == null) {
        throw Exception('Project ID not found in Service Account JSON');
      }

      return projectId;
    } catch (e) {
      _logger.e('Failed to extract project ID: $e');
      rethrow;
    }
  }

  /// Send notification to specific device tokens
  Future<NotificationHistory> sendNotificationToTokens({
    required ServiceAccount serviceAccount,
    required List<String> tokens,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    final startTime = DateTime.now();
    String? errorMessage;

    try {
      final client = await authenticate(serviceAccount.filePath);
      final projectId = await getProjectId(serviceAccount.filePath);

      final results = <String, dynamic>{};
      int successCount = 0;
      int failureCount = 0;

      // Send to each token
      for (final token in tokens) {
        try {
          final response = await _sendSingleMessage(
            client: client,
            projectId: projectId,
            token: token,
            title: title,
            body: body,
            imageUrl: imageUrl,
            data: data,
          );

          if (response.statusCode == 200) {
            successCount++;
            results[token] = 'success';
          } else {
            failureCount++;
            try {
              final errorBody =
                  jsonDecode(response.body) as Map<String, dynamic>;
              results[token] =
                  (errorBody['error'] as Map<String, dynamic>?)?['message'] ??
                  'Unknown error';
            } catch (_) {
              results[token] = 'Unknown error';
            }
          }
        } catch (e) {
          failureCount++;
          results[token] = e.toString();
        }
      }

      client.close();

      if (failureCount > 0) {
        errorMessage = 'Failed to send to $failureCount tokens';
      }

      _logger.i(
        'Sent to $successCount tokens, failed to send to $failureCount tokens',
      );

      return NotificationHistory(
        id: 0, // Will be set by database
        serviceAccountId: serviceAccount.id,
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data ?? {},
        targetTokens: tokens,
        topic: null,
        status: failureCount == 0 ? 'success' : 'partial',
        errorMessage: errorMessage,
        sentAt: startTime,
      );
    } catch (e) {
      _logger.e('Failed to send notification: $e');
      return NotificationHistory(
        id: 0,
        serviceAccountId: serviceAccount.id,
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data ?? {},
        targetTokens: tokens,
        topic: null,
        status: 'failed',
        errorMessage: e.toString(),
        sentAt: startTime,
      );
    }
  }

  /// Send notification to a topic
  Future<NotificationHistory> sendNotificationToTopic({
    required ServiceAccount serviceAccount,
    required String topic,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    final startTime = DateTime.now();
    String? errorMessage;

    try {
      final client = await authenticate(serviceAccount.filePath);
      final projectId = await getProjectId(serviceAccount.filePath);

      final response = await _sendTopicMessage(
        client: client,
        projectId: projectId,
        topic: topic,
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data,
      );

      client.close();

      if (response.statusCode != 200) {
        try {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage =
              (errorBody['error'] as Map<String, dynamic>?)?['message'] ??
              'Unknown error';
        } catch (_) {
          errorMessage = 'Unknown error';
        }
        _logger.e('Failed to send to topic: $errorMessage');
      } else {
        _logger.i('Successfully sent notification to topic: $topic');
      }

      return NotificationHistory(
        id: 0,
        serviceAccountId: serviceAccount.id,
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data ?? {},
        targetTokens: [],
        topic: topic,
        status: response.statusCode == 200 ? 'success' : 'failed',
        errorMessage: errorMessage,
        sentAt: startTime,
      );
    } catch (e) {
      _logger.e('Failed to send notification to topic: $e');
      return NotificationHistory(
        id: 0,
        serviceAccountId: serviceAccount.id,
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data ?? {},
        targetTokens: [],
        topic: topic,
        status: 'failed',
        errorMessage: e.toString(),
        sentAt: startTime,
      );
    }
  }

  /// Send a single message to a device token
  Future<http.Response> _sendSingleMessage({
    required AutoRefreshingAuthClient client,
    required String projectId,
    required String token,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    final message = <String, dynamic>{
      'message': {
        'token': token,
        'notification': {'title': title, 'body': body},
        'android': {
          'notification': {'notification_count': 1},
        },
        'apns': {
          'payload': {
            'aps': {'badge': 1},
          },
        },
      },
    };

    if (imageUrl != null) {
      (message['message']
              as Map<String, dynamic>)['android']?['notification']?['image'] =
          imageUrl;
      (message['message']
              as Map<
                String,
                dynamic
              >)['apns']?['payload']?['aps']?['mutable-content'] =
          1;
    }

    if (data != null && data.isNotEmpty) {
      (message['message'] as Map<String, dynamic>)['data'] = data;
    }

    final url = Uri.parse(
      '${AppConstants.fcmEndpoint}/$projectId/messages:send',
    );

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    return response;
  }

  /// Send a message to a topic
  Future<http.Response> _sendTopicMessage({
    required AutoRefreshingAuthClient client,
    required String projectId,
    required String topic,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    final message = <String, dynamic>{
      'message': {
        'topic': topic,
        'notification': {'title': title, 'body': body},
        'android': {
          'notification': {'notification_count': 1},
        },
        'apns': {
          'payload': {
            'aps': {'badge': 1},
          },
        },
      },
    };

    if (imageUrl != null) {
      (message['message']
              as Map<String, dynamic>)['android']?['notification']?['image'] =
          imageUrl;
      (message['message']
              as Map<
                String,
                dynamic
              >)['apns']?['payload']?['aps']?['mutable-content'] =
          1;
    }

    if (data != null && data.isNotEmpty) {
      (message['message'] as Map<String, dynamic>)['data'] = data;
    }

    final url = Uri.parse(
      '${AppConstants.fcmEndpoint}/$projectId/messages:send',
    );

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(message),
    );

    return response;
  }
}
