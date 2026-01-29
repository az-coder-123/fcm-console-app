import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Form fields for notification (title, body, image URL, topic)
class NotificationFormFields extends ConsumerWidget {
  final bool sendToTopic;

  const NotificationFormFields({required this.sendToTopic, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Send mode toggle
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Device Tokens'),
              icon: Icon(Icons.devices),
            ),
            ButtonSegment(
              value: true,
              label: Text('Topic'),
              icon: Icon(Icons.topic),
            ),
          ],
          selected: {sendToTopic},
          onSelectionChanged: (Set<bool> newSelection) {
            ref.read(notificationSendToTopicProvider.notifier).state =
                newSelection.first;
          },
        ),
        const Divider(),
        const SizedBox(height: 16),

        // Topic field (only visible when sending to topic)
        if (sendToTopic)
          TextField(
            onChanged: (value) {
              ref.read(notificationTopicProvider.notifier).state = value;
            },
            decoration: const InputDecoration(
              labelText: 'Topic Name',
              hintText: 'e.g., news, updates',
              prefixIcon: Icon(Icons.topic),
              border: OutlineInputBorder(),
            ),
          ),
        if (sendToTopic) const SizedBox(height: 16),

        // Title field
        TextField(
          onChanged: (value) {
            ref.read(notificationTitleProvider.notifier).state = value;
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
          onChanged: (value) {
            ref.read(notificationBodyProvider.notifier).state = value;
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
          onChanged: (value) {
            ref.read(notificationImageUrlProvider.notifier).state = value;
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
}
