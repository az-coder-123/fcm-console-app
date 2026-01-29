import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_form_state.dart';

/// Form fields for notification (title, body, image URL, topic)
/// Uses ConsumerStatefulWidget to maintain TextEditingControllers
class NotificationFormFields extends ConsumerStatefulWidget {
  const NotificationFormFields({super.key});

  @override
  ConsumerState<NotificationFormFields> createState() =>
      _NotificationFormFieldsState();
}

class _NotificationFormFieldsState
    extends ConsumerState<NotificationFormFields> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _imageUrlController;
  late TextEditingController _topicController;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(notificationFormProvider);
    final currentData = formState.currentModeData;
    _titleController = TextEditingController(text: currentData.title);
    _bodyController = TextEditingController(text: currentData.body);
    _imageUrlController = TextEditingController(text: currentData.imageUrl);
    _topicController = TextEditingController(text: formState.topicData.topic);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(notificationFormProvider);

    // Sync controllers with provider state (in case state changes externally)
    _syncControllers(formState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic field (only visible when sending to topic)
        if (formState.sendToTopic)
          TextField(
            controller: _topicController,
            onChanged: (value) {
              ref.read(notificationFormProvider.notifier).setTopic(value);
            },
            decoration: const InputDecoration(
              labelText: 'Topic Name',
              hintText: 'e.g., news, updates',
              prefixIcon: Icon(Icons.topic),
              border: OutlineInputBorder(),
            ),
          ),
        if (formState.sendToTopic) const SizedBox(height: 16),

        // Title field
        TextField(
          controller: _titleController,
          onChanged: (value) {
            ref.read(notificationFormProvider.notifier).setTitle(value);
          },
          decoration: const InputDecoration(
            labelText: 'Title *',
            hintText: 'Notification title',
            prefixIcon: Icon(Icons.title),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Body field
        TextField(
          controller: _bodyController,
          onChanged: (value) {
            ref.read(notificationFormProvider.notifier).setBody(value);
          },
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Body *',
            hintText: 'Notification body',
            prefixIcon: Icon(Icons.description),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Image URL field
        TextField(
          controller: _imageUrlController,
          onChanged: (value) {
            ref.read(notificationFormProvider.notifier).setImageUrl(value);
          },
          decoration: const InputDecoration(
            labelText: 'Image URL (Optional)',
            hintText: 'https://example.com/image.png',
            prefixIcon: Icon(Icons.image),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  /// Sync controllers with provider state when form state changes externally
  void _syncControllers(NotificationFormState formState) {
    final currentData = formState.currentModeData;
    if (_titleController.text != currentData.title) {
      _titleController.text = currentData.title;
    }
    if (_bodyController.text != currentData.body) {
      _bodyController.text = currentData.body;
    }
    if (_imageUrlController.text != currentData.imageUrl) {
      _imageUrlController.text = currentData.imageUrl;
    }
    if (_topicController.text != formState.topicData.topic) {
      _topicController.text = formState.topicData.topic;
    }
  }
}
