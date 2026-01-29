import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';
import '../models/notification_history.dart';
import '../models/service_account.dart';

/// Service for Firebase Cloud Messaging operations
/// Handles authentication and sending notifications via FCM v1 HTTP API
class FCMService {
  final Logger _logger = Logger();

  /// Load and parse Service Account JSON (from content or file path)
  Future<Map<String, dynamic>> _loadServiceAccountJson(
    String serviceAccountPath, {
    String? jsonContent,
  }) async {
    late final String jsonString;

    // If jsonContent is provided, use it directly
    if (jsonContent != null && jsonContent.isNotEmpty) {
      jsonString = jsonContent;
    } else {
      // Fall back to reading from file path with smart recovery
      jsonString = await _getServiceAccountContent(serviceAccountPath);
    }

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Authenticate with Google API using Service Account JSON
  Future<AutoRefreshingAuthClient> authenticate(
    String serviceAccountPath, {
    String? jsonContent,
  }) async {
    try {
      final json = await _loadServiceAccountJson(
        serviceAccountPath,
        jsonContent: jsonContent,
      );

      final credentials = ServiceAccountCredentials.fromJson(json);

      final client = await clientViaServiceAccount(credentials, [
        'https://www.googleapis.com/auth/firebase.messaging',
      ]);

      _logger.i('Successfully authenticated with Google API');
      return client;
    } catch (e) {
      _logger.e('Authentication failed: $e');
      debugPrint('Authentication failed: $e');
      debugPrintStack();
      rethrow;
    }
  }

  /// Get service account content with fallback strategies
  Future<String> _getServiceAccountContent(String serviceAccountPath) async {
    final file = File(serviceAccountPath);

    // Strategy 1: Try to read from the original path
    if (await file.exists()) {
      try {
        return await file.readAsString();
      } catch (e) {
        _logger.w('Failed to read from original path, trying alternatives: $e');
      }
    }

    // Strategy 2: Try to find a backup copy in app support directory
    try {
      final appDocDir = await getApplicationSupportDirectory();
      final List<FileSystemEntity> files = appDocDir.listSync(recursive: false);

      // Look for service account backup files
      for (final entity in files) {
        if (entity is File && entity.path.contains('service_account_')) {
          try {
            final content = await entity.readAsString();
            // Validate it looks like a service account
            final json = jsonDecode(content);
            if (json is Map && json.containsKey('project_id')) {
              _logger.i(
                'Successfully recovered service account from backup: ${entity.path}',
              );
              return content;
            }
          } catch (e) {
            _logger.w('Backup file is invalid: ${entity.path}');
          }
        }
      }
    } catch (e) {
      _logger.w('Failed to search for backup files: $e');
    }

    // Strategy 3: All strategies failed
    throw FileSystemException(
      'Cannot access service account file. This usually happens when the file is in the Downloads folder on macOS. '
      'Please re-upload the service account JSON from Settings to fix this issue.',
      serviceAccountPath,
    );
  }

  /// Extract project ID from Service Account JSON
  Future<String> getProjectId(
    String serviceAccountPath, {
    String? jsonContent,
  }) async {
    try {
      final data = await _loadServiceAccountJson(
        serviceAccountPath,
        jsonContent: jsonContent,
      );

      final projectId = data['project_id'];

      if (projectId == null) {
        throw Exception('Project ID not found in Service Account JSON');
      }

      return projectId;
    } catch (e) {
      _logger.e('Failed to extract project ID: $e');
      debugPrint('Failed to extract project ID: $e');
      debugPrintStack();
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
      final client = await authenticate(
        serviceAccount.filePath,
        jsonContent: serviceAccount.jsonContent,
      );
      final projectId = await getProjectId(
        serviceAccount.filePath,
        jsonContent: serviceAccount.jsonContent,
      );

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
            } catch (e) {
              debugPrint('Failed to parse error body for token $token: $e');
              debugPrintStack();
              results[token] = 'Unknown error';
            }
          }
        } catch (e) {
          failureCount++;
          results[token] = e.toString();
          debugPrint('Failed to send to token $token: $e');
          debugPrintStack();
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
      debugPrint('Failed to send notification: $e');
      debugPrintStack();
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
      final client = await authenticate(
        serviceAccount.filePath,
        jsonContent: serviceAccount.jsonContent,
      );
      final projectId = await getProjectId(
        serviceAccount.filePath,
        jsonContent: serviceAccount.jsonContent,
      );

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
        } catch (e) {
          debugPrint('Failed to parse topic error body: $e');
          debugPrintStack();
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
      debugPrint('Failed to send notification to topic: $e');
      debugPrintStack();
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
