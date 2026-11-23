import 'package:flutter/material.dart';

import 'shortlist_profiles.dart';

class ShortlistCounts extends StatelessWidget {
  const ShortlistCounts({super.key, required this.profiles});

  final ShortlistProfiles profiles;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: profiles,
        builder: (context, _) {
          final rooms = profiles.roomCounts;
          final branches = profiles.branchCounts;
          return AlertDialog(
            title: const Text('Shortlist counts'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!profiles.hasLinks)
                    const Text('No labeled enrollment numbers were found.')
                  else ...[
                    Text('Total students: ${profiles.total}'),
                    if (rooms.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('By room'),
                      for (final room in rooms.entries)
                        Text('${room.key}: ${room.value}'),
                      if (profiles.unknownRooms > 0)
                        Text('Room unavailable: ${profiles.unknownRooms}'),
                    ],
                    const SizedBox(height: 16),
                    const Text('By branch'),
                    for (final branch in branches.entries)
                      Text('${branch.key}: ${branch.value}'),
                    if (profiles.pending > 0)
                      Text('Loading: ${profiles.pending}'),
                    if (profiles.unavailable > 0)
                      Text('Branch unavailable: ${profiles.unavailable}'),
                    if (profiles.signInRequired)
                      const Text(
                          'Sign in again to look up remaining branches.'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
}
