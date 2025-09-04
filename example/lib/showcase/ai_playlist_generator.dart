import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

void main() {
  // Make the system navigation bar transparent on Android.
  if (defaultTargetPlatform == TargetPlatform.android) {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    ).then((_) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ));
    });
  }

  runApp(const _AiPlaylistGeneratorExample());
}

class _AiPlaylistGeneratorExample extends StatelessWidget {
  const _AiPlaylistGeneratorExample();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

// ----------------------------------------------------------
// Routes
// ----------------------------------------------------------

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _Root(),
      routes: [_sheetShellRoute],
    ),
  ],
);

final _nestedNavigatorKey = GlobalKey<NavigatorState>();

// A ShellRoute is used to create a new Navigator for nested navigation in the sheet.
final _sheetShellRoute = ShellRoute(
  navigatorKey: _nestedNavigatorKey,
  pageBuilder: (context, state, navigator) {
    // Use ModalSheetPage to show a modal sheet.
    return ModalSheetPage(
      swipeDismissible: true,
      viewportPadding: EdgeInsets.only(
        // Add the top padding to avoid the status bar.
        top: MediaQuery.viewPaddingOf(context).top,
      ),
      child: _SheetShell(
        navigator: navigator,
      ),
    );
  },
  routes: [_introRoute],
);

final _introRoute = GoRoute(
  path: 'intro',
  pageBuilder: (context, state) {
    return const PagedSheetPage(
      // Use a custom transition builder.
      transitionsBuilder: _fadeAndSlideTransitionWithIOSBackGesture,
      child: _IntroPage(),
    );
  },
  routes: [_genreRoute],
);

final _genreRoute = GoRoute(
  path: 'genre',
  pageBuilder: (context, state) {
    return const PagedSheetPage(
      transitionsBuilder: _fadeAndSlideTransitionWithIOSBackGesture,
      child: _SelectGenrePage(),
    );
  },
  routes: [_moodRoute],
);

final _moodRoute = GoRoute(
  path: 'mood',
  pageBuilder: (context, state) {
    return const PagedSheetPage(
      transitionsBuilder: _fadeAndSlideTransitionWithIOSBackGesture,
      child: _SelectMoodPage(),
    );
  },
  routes: [_seedTrackRoute],
);

final _seedTrackRoute = GoRoute(
  path: 'seed-track',
  pageBuilder: (context, state) {
    return const PagedSheetPage(
      transitionsBuilder: _fadeAndSlideTransitionWithIOSBackGesture,
      scrollConfiguration: SheetScrollConfiguration(),
      child: _SelectSeedTrackPage(),
    );
  },
  routes: [_confirmRoute],
);

final _confirmRoute = GoRoute(
  path: 'confirm',
  pageBuilder: (context, state) {
    return const PagedSheetPage(
      transitionsBuilder: _fadeAndSlideTransitionWithIOSBackGesture,
      scrollConfiguration: SheetScrollConfiguration(),
      initialOffset: SheetOffset(0.7),
      snapGrid: SheetSnapGrid(
        snaps: [SheetOffset(0.7), SheetOffset(1)],
      ),
      child: _ConfirmPage(),
    );
  },
  routes: [_generateRoute],
);

final _generateRoute = GoRoute(
  path: 'generate',
  pageBuilder: (context, state) {
    return const PagedSheetPage(
      transitionsBuilder: _fadeAndSlideTransitionWithIOSBackGesture,
      child: _GeneratingPage(),
    );
  },
);

// ----------------------------------------------------------
// Pages
// ----------------------------------------------------------

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: ElevatedButton(
        onPressed: () => context.go('/intro'),
        child: const Text('Generate Playlist'),
      ),
    ));
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.navigator,
  });

  final Widget navigator;

  @override
  Widget build(BuildContext context) {
    Future<bool?> showCancelDialog() {
      return showDialog<bool?>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Are you sure?'),
            content:
                const Text('Do you want to cancel the playlist generation?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
            ],
          );
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await showCancelDialog() ?? false;
          if (shouldPop && context.mounted) {
            context.go('/');
          }
        }
      },
      child: PagedSheet(
        decoration: MaterialSheetDecoration(
          size: SheetSize.stretch,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          color: Theme.of(context).colorScheme.surface,
        ),
        builder: (context, child) {
          return SheetContentScaffold(
            bottomBarVisibility: const BottomBarVisibility.always(),
            extendBodyBehindTopBar: true,
            extendBodyBehindBottomBar: true,
            topBar: const _SharedSheetTopBar(),
            body: child,
            bottomBar: const _SharedSheetBottomBar(),
          );
        },
        navigator: navigator,
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Hello there!\n"
              "I'm your AI music assistant. "
              "Ready to create the perfect playlist for you. 😊",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMediumBold,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectGenrePage extends StatelessWidget {
  const _SelectGenrePage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        bottom: MediaQuery.paddingOf(context).bottom + 8,
        left: 32,
        right: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'What genre do you like? (1/3)',
            style: Theme.of(context).textTheme.headlineMediumBold,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            children: [
              for (final genre in _genres)
                _SelectableChip(
                  label: Text(genre),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectMoodPage extends StatelessWidget {
  const _SelectMoodPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'What kind of mood are you aiming for in this playlist? (2/3)',
                  style: Theme.of(context).textTheme.headlineMediumBold,
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: _SelectableMoodList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectSeedTrackPage extends StatelessWidget {
  const _SelectSeedTrackPage();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _seedTracks.length + 1,
      itemBuilder: (context, index) {
        return switch (index) {
          0 => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text(
                'Select seed tracks to get started (3/3)',
                style: Theme.of(context).textTheme.headlineMediumBold,
              ),
            ),
          _ => _SelectableListTile(
              padding: const EdgeInsets.only(left: 16),
              title: _seedTracks[index - 1],
            ),
        };
      },
    );
  }
}

class _ConfirmPage extends StatelessWidget {
  const _ConfirmPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: Text(
                    'Confirm your choices',
                    style: Theme.of(context).textTheme.headlineMediumBold,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  title: const Text('Genres'),
                  trailing: IconButton(
                    onPressed: () => context.go('/intro/genre'),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: Wrap(
                    spacing: 10,
                    children: [
                      for (final genre in _genres.take(5))
                        FilterChip(
                          selected: true,
                          label: Text(genre),
                          onSelected: (_) {},
                        ),
                    ],
                  ),
                ),
                const Divider(height: 32),
                ListTile(
                  title: const Text('Mood'),
                  trailing: IconButton(
                    onPressed: () => context.go('/intro/genre/mood'),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
                RadioListTile(
                  title: Text(_moods.first.label),
                  secondary: Text(
                    _moods.first.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  controlAffinity: ListTileControlAffinity.trailing,
                  value: '',
                  // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
                  // ignore: deprecated_member_use
                  groupValue: '',
                  // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
                  // ignore: deprecated_member_use
                  onChanged: (_) {},
                ),
                const Divider(height: 32),
                ListTile(
                  title: const Text('Seed tracks'),
                  trailing: IconButton(
                    onPressed: () => context.go('/intro/genre/mood/seed-track'),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              ],
            ),
          ),
          SliverList.builder(
            itemCount: (_seedTracks.length * 0.4).floor(),
            itemBuilder: (context, index) {
              return CheckboxListTile(
                title: Text(_seedTracks[index]),
                value: true,
                onChanged: (_) {},
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GeneratingPage extends StatelessWidget {
  const _GeneratingPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Generating your playlist...',
                style: Theme.of(context).textTheme.headlineMediumBold,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: CircularProgressIndicator(strokeWidth: 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// Utilities
// ----------------------------------------------------------

extension on TextTheme {
  TextStyle? get headlineMediumBold =>
      headlineMedium?.copyWith(fontWeight: FontWeight.bold);
}

class _SelectableChip extends StatefulWidget {
  const _SelectableChip({
    required this.label,
  });

  final Widget label;

  @override
  State<_SelectableChip> createState() => _SelectableChipState();
}

class _SelectableChipState extends State<_SelectableChip> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      onSelected: (isSelected) {
        setState(() => this.isSelected = isSelected);
      },
      selected: isSelected,
      label: widget.label,
    );
  }
}

class _SelectableListTile extends StatefulWidget {
  const _SelectableListTile({
    required this.title,
    required this.padding,
  });

  final String title;
  final EdgeInsets padding;

  @override
  State<_SelectableListTile> createState() => _SelectableListTileState();
}

class _SelectableListTileState extends State<_SelectableListTile> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: CheckboxListTile(
        title: Text(widget.title),
        value: isSelected,
        onChanged: (selected) {
          setState(() => isSelected = selected!);
        },
      ),
    );
  }
}

class _SelectableMoodList extends StatefulWidget {
  const _SelectableMoodList();

  @override
  State<_SelectableMoodList> createState() => _SelectableMoodListState();
}

class _SelectableMoodListState extends State<_SelectableMoodList> {
  String? selectedMood = _moods.first.label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final mood in _moods)
          RadioListTile(
            title: Text(mood.label),
            secondary: Text(
              mood.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            selected: mood.label == selectedMood,
            value: mood.label,
            // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
            // ignore: deprecated_member_use
            groupValue: selectedMood,
            // TODO: Migrate to RadioGroup when minimum SDK version is raised to 3.35.0
            // ignore: deprecated_member_use
            onChanged: (newMooed) => setState(() {
              selectedMood = newMooed;
            }),
          ),
      ],
    );
  }
}

class _SharedSheetTopBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _SharedSheetTopBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    void onTap() {
      final nestedNavigator = _nestedNavigatorKey.currentState!;
      if (nestedNavigator.canPop()) {
        nestedNavigator.pop();
      } else {
        context.go('/');
      }
    }

    final location = GoRouterState.of(context).fullPath!.split('/').last;
    final (icon, enabled) = switch (location) {
      'intro' => (const Icon(Icons.close), true),
      'generate' => (Icon(Icons.arrow_back_ios_new_outlined), false),
      _ => (const Icon(Icons.arrow_back_ios_new_outlined), true),
    };

    return AppBar(
      leading: IconButton(
        onPressed: enabled ? onTap : null,
        icon: icon,
      ),
    );
  }
}

class _SharedSheetBottomBar extends StatelessWidget {
  const _SharedSheetBottomBar();

  @override
  Widget build(BuildContext context) {
    final router = GoRouterState.of(context);

    Future<void> onTap() async {
      switch (router.fullPath?.split('/').last) {
        case 'intro':
          context.go('/intro/genre');
        case 'genre':
          context.go('/intro/genre/mood');
        case 'mood':
          context.go('/intro/genre/mood/seed-track');
        case 'seed-track':
          context.go('/intro/genre/mood/seed-track/confirm');
        case 'confirm':
          context.go('/intro/genre/mood/seed-track/confirm/generate');
          await Future.delayed(Duration(seconds: 1));
          if (context.mounted) {
            context.go('/');
          }
      }
    }

    final (label, isEnabled) = switch (router.fullPath?.split('/').last) {
      'confirm' => (const Text('Generate'), true),
      'generate' => (const Text('Generate'), false),
      _ => (const Text('Next'), true),
    };

    const horizontalPadding = 32.0;
    const verticalPadding = 16.0;

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding,
              horizontalPadding,
              max(MediaQuery.viewPaddingOf(context).bottom, verticalPadding),
            ),
            child: FilledButton(
              onPressed: isEnabled ? onTap : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: label,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _fadeAndSlideTransitionWithIOSBackGesture(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final PageTransitionsTheme theme = Theme.of(context).pageTransitionsTheme;
  return FadeTransition(
    opacity: CurveTween(curve: Curves.easeInExpo).animate(animation),
    child: FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeOutExpo))
          .animate(secondaryAnimation),
      child: theme.buildTransitions(
        ModalRoute.of(context) as PageRoute,
        context,
        animation,
        secondaryAnimation,
        child,
      ),
    ),
  );
}

// ----------------------------------------------------------
// Constants
// ----------------------------------------------------------

const _genres = [
  'Pop',
  'Rock',
  'Hip Hop',
  'R&B',
  'Country',
  'Jazz',
  'Classical',
  'Electronic',
  'Folk',
  'Reggae',
  'Blues',
  'Metal',
  'Punk',
  'Disco',
  'Funk',
  'Soul',
  'Techno',
  'House',
  'Ambient',
  'Indie',
  'Alternative',
  'K-Pop',
  'Latin',
];

const _moods = [
  (label: 'Energetic and Upbeat', emoji: '🎉'),
  (label: 'Laid-back and Chill:', emoji: '🍹'),
  (label: 'Mellow and Reflective', emoji: '🛌'),
  (label: 'Uplifting and Positive', emoji: '💪'),
];

/* cSpell: disable */
const _seedTracks = [
  "Groove Odyssey",
  "Funky Fusion Fiesta",
  "Soul Serenade Shuffle",
  "Rhythm Revival Rendezvous",
  "Bassline Bliss",
  "Jazzed-up Jamboree",
  "Funkadelic Dreamscape",
  "Smooth Sunset Serenity",
  "Electric Euphoria Express",
  "Syncopation Celebration",
  "Funky Mirage Melody",
  "Saxophone Sunshine Soiree",
  "Dancefloor Diplomacy",
  "Bass Bounce Bonanza",
  "Vibraphone Voyage",
  "Funk Frontier Fantasy",
  "Sonic Soul Safari",
  "Guitar Groove Gala",
  "Brass Bliss Bouquet",
  "Funky Cosmic Carnival",
];
/* cSpell: enable */
