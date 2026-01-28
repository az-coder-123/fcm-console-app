/// Service for handling Google OAuth authentication using Service Account.
library;

import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/exceptions.dart';

/// Service for Google authentication using Service Account credentials.
class GoogleAuthService {
  GoogleAuthService._();

  static GoogleAuthService? _instance;
  static AutoRefreshingAuthClient? _authClient;
  static String? _currentProjectId;

  /// Gets the singleton instance.
  static GoogleAuthService get instance {
    _instance ??= GoogleAuthService._();
    return _instance!;
  }

  /// Gets the current project ID.
  String? get currentProjectId => _currentProjectId;

  /// Authenticates using a Service Account JSON file.
  ///
  /// Returns an authenticated HTTP client that auto-refreshes tokens.
  Future<AutoRefreshingAuthClient> authenticate(String jsonPath) async {
    try {
      final file = File(jsonPath);
      if (!await file.exists()) {
        throw ServiceAccountException(
          'Service Account file not found: $jsonPath',
        );
      }

      final jsonContent = await file.readAsString();
      final credentials = ServiceAccountCredentials.fromJson(jsonContent);

      _currentProjectId = json.decode(jsonContent)['project_id'] as String?;

      _authClient = await clientViaServiceAccount(credentials, [
        FcmConstants.fcmScope,
      ]);

      return _authClient!;
    } on FormatException catch (e) {
      throw ServiceAccountException('Invalid JSON format: ${e.message}');
    } on Exception catch (e) {
      throw ServiceAccountException('Authentication failed: $e');
    }
  }

  /// Authenticates using a JSON string content.
  Future<AutoRefreshingAuthClient> authenticateFromString(
    String jsonContent,
  ) async {
    try {
      final credentials = ServiceAccountCredentials.fromJson(jsonContent);

      _currentProjectId = json.decode(jsonContent)['project_id'] as String?;

      _authClient = await clientViaServiceAccount(credentials, [
        FcmConstants.fcmScope,
      ]);

      return _authClient!;
    } on FormatException catch (e) {
      throw ServiceAccountException('Invalid JSON format: ${e.message}');
    } on Exception catch (e) {
      throw ServiceAccountException('Authentication failed: $e');
    }
  }

  /// Gets the current authenticated client.
  ///
  /// Throws if not authenticated.
  AutoRefreshingAuthClient get client {
    if (_authClient == null) {
      throw ServiceAccountException(
        'Not authenticated. Call authenticate() first.',
      );
    }
    return _authClient!;
  }

  /// Gets the current access token.
  String? get accessToken => _authClient?.credentials.accessToken.data;

  /// Checks if currently authenticated.
  bool get isAuthenticated => _authClient != null && _currentProjectId != null;

  /// Closes the auth client and clears state.
  void dispose() {
    _authClient?.close();
    _authClient = null;
    _currentProjectId = null;
  }
}

/// Service for sending FCM notifications via HTTP v1 API.
class FcmService {
  FcmService(this._authService);

  final GoogleAuthService _authService;

  /// Sends a notification to a single device token.
  Future<FcmSendResult> sendToToken({
    required String token,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, String>? data,
  }) async {
    final projectId = _authService.currentProjectId;
    if (projectId == null) {
      throw FcmException('No project ID available. Authenticate first.');
    }

    final url = FcmConstants.fcmBaseUrl.replaceAll('{project_id}', projectId);

    final message = _buildMessage(
      token: token,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
    );

    return _sendRequest(url, message);
  }

  /// Sends a notification to multiple device tokens.
  Future<List<FcmSendResult>> sendToTokens({
    required List<String> tokens,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, String>? data,
  }) async {
    final results = <FcmSendResult>[];

    for (final token in tokens) {
      try {
        final result = await sendToToken(
          token: token,
          title: title,
          body: body,
          imageUrl: imageUrl,
          data: data,
        );
        results.add(result);
      } on Exception catch (e) {
        results.add(
          FcmSendResult(success: false, token: token, error: e.toString()),
        );
      }
    }

    return results;
  }

  /// Sends a notification to a topic.
  Future<FcmSendResult> sendToTopic({
    required String topic,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, String>? data,
  }) async {
    final projectId = _authService.currentProjectId;
    if (projectId == null) {
      throw FcmException('No project ID available. Authenticate first.');
    }

    final url = FcmConstants.fcmBaseUrl.replaceAll('{project_id}', projectId);

    final message = _buildMessage(
      topic: topic,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
    );

    return _sendRequest(url, message);
  }

  /// Builds the FCM message payload.
  Map<String, dynamic> _buildMessage({
    String? token,
    String? topic,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, String>? data,
  }) {
    final notification = <String, dynamic>{'title': title, 'body': body};

    if (imageUrl != null && imageUrl.isNotEmpty) {
      notification['image'] = imageUrl;
    }

    final message = <String, dynamic>{'notification': notification};

    if (token != null) {
      message['token'] = token;
    } else if (topic != null) {
      message['topic'] = topic;
    }

    if (data != null && data.isNotEmpty) {
      message['data'] = data;
    }

    return {'message': message};
  }

  /// Sends the HTTP request to FCM.
  Future<FcmSendResult> _sendRequest(
    String url,
    Map<String, dynamic> payload,
  ) async {
    try {
      final client = _authService.client;

      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        return FcmSendResult(
          success: true,
          messageId: responseData['name'] as String?,
        );
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final error = errorData['error'] as Map<String, dynamic>?;
        return FcmSendResult(
          success: false,
          error: error?['message'] as String? ?? 'Unknown error',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      return FcmSendResult(
        success: false,
        error: 'Network error: ${e.message}',
      );
    } on Exception catch (e) {
      return FcmSendResult(success: false, error: e.toString());
    }
  }
}

/// Result of an FCM send operation.
class FcmSendResult {
  const FcmSendResult({
    required this.success,
    this.messageId,
    this.token,
    this.error,
    this.statusCode,
  });

  /// Whether the send was successful.
  final bool success;

  /// The message ID from FCM (if successful).
  final String? messageId;

  /// The target token (for batch operations).
  final String? token;

  /// Error message (if failed).
  final String? error;

  /// HTTP status code (if failed).
  final int? statusCode;
}
