import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/job_assignment_model.dart';
import '../widgets/job_detail_view.dart';

class JobDetailScreen extends StatelessWidget {
  final ActiveJob job;
  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Job Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: JobDetailView(job: job),
      ),
    );
  }
}
