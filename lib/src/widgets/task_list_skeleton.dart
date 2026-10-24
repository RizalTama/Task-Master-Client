import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TaskListSkeleton extends StatelessWidget {
  const TaskListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        padding: const EdgeInsets.all(8.0),
        itemCount: 6, // Display 6 skeleton items
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.white,
              ),
              title: Container(
                height: 16,
                width: MediaQuery.of(context).size.width * 0.6,
                color: Colors.white,
              ),
              subtitle: Container(
                height: 12,
                width: MediaQuery.of(context).size.width * 0.4,
                color: Colors.white,
              ),
              trailing: Container(
                height: 24,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
