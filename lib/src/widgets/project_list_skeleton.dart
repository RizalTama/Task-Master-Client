import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProjectListSkeleton extends StatelessWidget {
  const ProjectListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        padding: const EdgeInsets.all(8.0),
        itemCount: 5, // Display 5 skeleton items
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
              ),
              title: Container(
                height: 16,
                width: MediaQuery.of(context).size.width * 0.5,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
