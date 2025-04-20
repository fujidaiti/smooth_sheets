// ignore_for_file: unreachable_from_main
import 'dart:convert';
import 'dart:io';

import 'package:grinder/grinder.dart';

void main(List<String> args) => grind(args);

@Task(
  'Updates CHANGELOG.md from the git history using git-cliff. '
  'All conventional commits are kept as is, while non-conventional commits'
  'are simplified to a single line message. ',
)
void updateChangelog() {
  final changelogFile = getFile('CHANGELOG.md');
  _runGitCliff(output: changelogFile, bump: true);
}

@Task(
  'Generates a list of commits that will be included in the next release. '
  'An output file must be specified with --output.',
)
void unreleasedCommits() {
  final output = context.invocation.arguments.getOption('output');
  if (output == null) {
    fail('Specify an output file with --output.');
  }

  _runGitCliff(output: getFile(output), unreleased: true, stripAll: true);
}

void _runGitCliff({
  required File output,
  bool unreleased = false,
  bool bump = false,
  bool stripAll = false,
}) {
  final contextFile = getFile('${buildDir.path}/git-cliff-context.json');
  contextFile.createSync(recursive: true);
  output.createSync(recursive: true);

  run(
    'git',
    arguments: [
      'cliff',
      if (bump) '--bump',
      if (unreleased) '--unreleased',
      '--context',
      '--output',
      contextFile.path,
    ],
  );

  late final List<dynamic> cliffContext;
  try {
    cliffContext = jsonDecode(contextFile.readAsStringSync()) as List<dynamic>;
  } on FormatException catch (error) {
    log('Error decoding JSON from git-cliff: $error');
    fail('Failed to parse context data.');
  }

  // Ensure all non-conventional commits have a single line message.
  for (final release in cliffContext) {
    final commits = (release as Map<String, dynamic>)['commits'];
    for (final commit in commits as List<dynamic>) {
      if (commit
          case {
            'conventional': false,
            'message': final String message,
            'raw_message': final String rawMessage,
          }) {
        commit['message'] = message.split('\n').first.trim();
        commit['raw_message'] = rawMessage.split('\n').first.trim();
      }
    }
  }

  contextFile.writeAsStringSync(jsonEncode(cliffContext));

  // Run git-cliff again with the cleaned context
  run(
    'git',
    arguments: [
      'cliff',
      '--from-context',
      contextFile.path,
      '--output',
      output.path,
      if (stripAll) '--strip=all',
    ],
  );
}
