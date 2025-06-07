import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class UtilityFunctionsExample extends StatefulWidget {
  const UtilityFunctionsExample({super.key});

  @override
  State<UtilityFunctionsExample> createState() =>
      _UtilityFunctionsExampleState();
}

class _UtilityFunctionsExampleState extends State<UtilityFunctionsExample> {
  String? lastResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utility Functions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Utility Functions for Modal Sheets',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'These utility functions provide a convenient way to show modal sheets, similar to showModalBottomSheet() in Flutter.',
            ),
            const SizedBox(height: 24),
            if (lastResult != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Last result: $lastResult'),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () => _showModalSheet(context),
              child: const Text('Show Material Modal Sheet'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showCupertinoModalSheet(context),
              child: const Text('Show Cupertino Modal Sheet'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showAdaptiveModalSheet(context),
              child: const Text('Show Adaptive Modal Sheet'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Note: The adaptive modal sheet automatically chooses between Material and Cupertino styles based on the current platform.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showModalSheet(BuildContext context) async {
    final result = await showModalSheet<String>(
      context: context,
      swipeDismissible: true,
      builder: (context) => _buildSheetContent(
        context,
        title: 'Material Modal Sheet',
        subtitle: 'Using showModalSheet()',
        color: Theme.of(context).primaryColor,
      ),
    );

    if (result != null) {
      setState(() => lastResult = result);
    }
  }

  Future<void> _showCupertinoModalSheet(BuildContext context) async {
    final result = await showCupertinoModalSheet<String>(
      context: context,
      swipeDismissible: true,
      builder: (context) => _buildSheetContent(
        context,
        title: 'Cupertino Modal Sheet',
        subtitle: 'Using showCupertinoModalSheet()',
        color: Colors.blue,
      ),
    );

    if (result != null) {
      setState(() => lastResult = result);
    }
  }

  Future<void> _showAdaptiveModalSheet(BuildContext context) async {
    final result = await showAdaptiveModalSheet<String>(
      context: context,
      swipeDismissible: true,
      builder: (context) => _buildSheetContent(
        context,
        title: 'Adaptive Modal Sheet',
        subtitle: 'Using showAdaptiveModalSheet()',
        color: Colors.purple,
      ),
    );

    if (result != null) {
      setState(() => lastResult = result);
    }
  }

  Widget _buildSheetContent(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Icon(
                Icons.layers,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Text(
                'This modal sheet was created using a utility function. You can swipe down to dismiss it or use the buttons below.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, 'Confirmed!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
