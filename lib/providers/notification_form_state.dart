import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data class for a specific notification mode (Device Tokens or Topic)
class FormModeData {
  final String title;
  final String body;
  final String imageUrl;
  final String topic; // Only used in Topic mode
  final Map<String, String> dataPairs;

  const FormModeData({
    this.title = '',
    this.body = '',
    this.imageUrl = '',
    this.topic = '',
    this.dataPairs = const {},
  });

  FormModeData copyWith({
    String? title,
    String? body,
    String? imageUrl,
    String? topic,
    Map<String, String>? dataPairs,
  }) {
    return FormModeData(
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      topic: topic ?? this.topic,
      dataPairs: dataPairs ?? this.dataPairs,
    );
  }
}

/// Immutable class representing the notification form state
/// Each send mode (Device Tokens / Topic) has its own data
class NotificationFormState {
  // Mode-specific data
  final FormModeData deviceTokensData;
  final FormModeData topicData;

  // Shared state
  final bool sendToTopic;
  final Set<String> selectedTokens;

  const NotificationFormState({
    this.deviceTokensData = const FormModeData(),
    this.topicData = const FormModeData(),
    this.sendToTopic = false,
    this.selectedTokens = const {},
  });

  /// Get current mode's form data
  FormModeData get currentModeData =>
      sendToTopic ? topicData : deviceTokensData;

  /// Create a copy of this state with optional field overrides
  NotificationFormState copyWith({
    FormModeData? deviceTokensData,
    FormModeData? topicData,
    bool? sendToTopic,
    Set<String>? selectedTokens,
  }) {
    return NotificationFormState(
      deviceTokensData: deviceTokensData ?? this.deviceTokensData,
      topicData: topicData ?? this.topicData,
      sendToTopic: sendToTopic ?? this.sendToTopic,
      selectedTokens: selectedTokens ?? this.selectedTokens,
    );
  }

  /// Reset form to initial state
  NotificationFormState reset() {
    return const NotificationFormState();
  }
}

/// StateNotifier for managing notification form state
class NotificationFormNotifier extends StateNotifier<NotificationFormState> {
  NotificationFormNotifier() : super(const NotificationFormState());

  // Title setter for current mode
  void setTitle(String value) {
    if (state.sendToTopic) {
      state = state.copyWith(topicData: state.topicData.copyWith(title: value));
    } else {
      state = state.copyWith(
        deviceTokensData: state.deviceTokensData.copyWith(title: value),
      );
    }
  }

  // Body setter for current mode
  void setBody(String value) {
    if (state.sendToTopic) {
      state = state.copyWith(topicData: state.topicData.copyWith(body: value));
    } else {
      state = state.copyWith(
        deviceTokensData: state.deviceTokensData.copyWith(body: value),
      );
    }
  }

  // Image URL setter for current mode
  void setImageUrl(String value) {
    if (state.sendToTopic) {
      state = state.copyWith(
        topicData: state.topicData.copyWith(imageUrl: value),
      );
    } else {
      state = state.copyWith(
        deviceTokensData: state.deviceTokensData.copyWith(imageUrl: value),
      );
    }
  }

  // Topic name setter (only for topic mode)
  void setTopic(String value) {
    state = state.copyWith(topicData: state.topicData.copyWith(topic: value));
  }

  // Data pairs setter for current mode
  void setDataPairs(Map<String, String> value) {
    if (state.sendToTopic) {
      state = state.copyWith(
        topicData: state.topicData.copyWith(dataPairs: value),
      );
    } else {
      state = state.copyWith(
        deviceTokensData: state.deviceTokensData.copyWith(dataPairs: value),
      );
    }
  }

  void setSendToTopic(bool value) {
    state = state.copyWith(sendToTopic: value);
  }

  void setSelectedTokens(Set<String> value) {
    state = state.copyWith(selectedTokens: value);
  }

  void addDataPair(String key, String value) {
    final currentData = state.currentModeData;
    final updatedPairs = {...currentData.dataPairs, key: value};

    if (state.sendToTopic) {
      state = state.copyWith(
        topicData: state.topicData.copyWith(dataPairs: updatedPairs),
      );
    } else {
      state = state.copyWith(
        deviceTokensData: state.deviceTokensData.copyWith(
          dataPairs: updatedPairs,
        ),
      );
    }
  }

  void removeDataPair(String key) {
    final currentData = state.currentModeData;
    final updatedPairs = {...currentData.dataPairs}..remove(key);

    if (state.sendToTopic) {
      state = state.copyWith(
        topicData: state.topicData.copyWith(dataPairs: updatedPairs),
      );
    } else {
      state = state.copyWith(
        deviceTokensData: state.deviceTokensData.copyWith(
          dataPairs: updatedPairs,
        ),
      );
    }
  }

  void toggleToken(String token) {
    final updatedTokens = {...state.selectedTokens};
    if (updatedTokens.contains(token)) {
      updatedTokens.remove(token);
    } else {
      updatedTokens.add(token);
    }
    state = state.copyWith(selectedTokens: updatedTokens);
  }

  void clearSelectedTokens() {
    state = state.copyWith(selectedTokens: {});
  }

  void reset() {
    state = state.reset();
  }
}

/// Provider for notification form state
/// This provider uses StateNotifierProvider (non-autoDispose)
/// which means it will NEVER be disposed - state persists permanently
final notificationFormProvider =
    StateNotifierProvider<NotificationFormNotifier, NotificationFormState>((
      ref,
    ) {
      return NotificationFormNotifier();
    });
