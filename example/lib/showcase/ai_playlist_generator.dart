import 'dart:async';

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

final sheetTransitionObserver = NavigationSheetTransitionObserver();

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _Root(),
      routes: [_sheetShellRoute],
    ),
  ],
);

// A ShellRoute is used to create a new Navigator for nested navigation in the sheet.
final _sheetShellRoute = ShellRoute(
  observers: [sheetTransitionObserver],
  pageBuilder: (context, state, navigator) {
    // Use ModalSheetPage to show a modal sheet.
    return ModalSheetPage(
      swipeDismissible: true,
      child: _SheetShell(
        navigator: navigator,
        transitionObserver: sheetTransitionObserver,
      ),
    );
  },
  routes: [_introRoute],
);

final _introRoute = GoRoute(
  path: 'intro',
  pageBuilder: (context, state) {
    return const DraggableNavigationSheetPage(child: _IntroPage());
  },
  routes: [_genreRoute],
);

final _genreRoute = GoRoute(
  path: 'genre',
  pageBuilder: (context, state) {
    return const DraggableNavigationSheetPage(child: _SelectGenrePage());
  },
  routes: [_moodRoute],
);

final _moodRoute = GoRoute(
  path: 'mood',
  pageBuilder: (context, state) {
    return const DraggableNavigationSheetPage(child: _SelectMoodPage());
  },
  routes: [_seedTrackRoute],
);

final _seedTrackRoute = GoRoute(
  path: 'seed-track',
  pageBuilder: (context, state) {
    return const ScrollableNavigationSheetPage(child: _SelectSeedTrackPage());
  },
  routes: [_confirmRoute],
);

final _confirmRoute = GoRoute(
  path: 'confirm',
  pageBuilder: (context, state) {
    return const ScrollableNavigationSheetPage(
      initialPosition: SheetAnchor.proportional(0.7),
      minPosition: SheetAnchor.proportional(0.7),
      physics: BouncingSheetPhysics(
        parent: SnappingSheetPhysics(),
      ),
      child: _ConfirmPage(),
    );
  },
  routes: [_generateRoute],
);

final _generateRoute = GoRoute(
  path: 'generate',
  pageBuilder: (context, state) {
    return const DraggableNavigationSheetPage(child: _GeneratingPage());
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
    required this.transitionObserver,
    required this.navigator,
  });

  final NavigationSheetTransitionObserver transitionObserver;
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

    return SafeArea(
      bottom: false,
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (!didPop) {
            final shouldPop = await showCancelDialog() ?? false;
            if (shouldPop && context.mounted) {
              context.go('/');
            }
          }
        },
        child: SheetViewport(
          child: NavigationSheet(
            transitionObserver: sheetTransitionObserver,
            child: Material(
              // Add circular corners to the sheet.
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              color: Theme.of(context).colorScheme.surface,
              child: navigator,
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context) {
    return SheetContentScaffold(
      appBar: _SharedAppBarHero(
        appbar: AppBar(
          leading: IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.close),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 8,
          ),
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
              const SizedBox(height: 64),
              FilledButton(
                onPressed: () => context.go('/intro/genre'),
                style: _largeFilledButtonStyle,
                child: const Text('Continue'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                style: _largeTextButtonStyle,
                child: const Text('No, thanks'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectGenrePage extends StatelessWidget {
  const _SelectGenrePage();

  @override
  Widget build(BuildContext context) {
    return SheetContentScaffold(
      appBar: _SharedAppBarHero(appbar: AppBar()),
      // Wrap the body in a SingleChildScrollView to prevent
      // the content from overflowing on small screens.
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 32,
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
      ),
      bottomBar: _BottomActionBar(
        label: 'Next',
        onPressed: () => context.go('/intro/genre/mood'),
      ),
    );
  }
}

class _SelectMoodPage extends StatelessWidget {
  const _SelectMoodPage();

  @override
  Widget build(BuildContext context) {
    return SheetContentScaffold(
      appBar: _SharedAppBarHero(appbar: AppBar()),
      body: SingleChildScrollView(
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
      bottomBar: _BottomActionBar(
        label: 'Next',
        onPressed: () => context.go('/intro/genre/mood/seed-track'),
      ),
    );
  }
}

class _SelectSeedTrackPage extends StatelessWidget {
  const _SelectSeedTrackPage();

  @override
  Widget build(BuildContext context) {
    return SheetContentScaffold(
      appBar: _SharedAppBarHero(appbar: AppBar()),
      body: ListView.builder(
        itemCount: _seedTracks.length + 1,
        itemBuilder: (context, index) {
          return switch (index) {
            0 => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
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
      ),
      bottomBar: _BottomActionBar(
        label: 'Next',
        showDivider: true,
        onPressed: () => context.go('/intro/genre/mood/seed-track/confirm'),
      ),
    );
  }
}

class _ConfirmPage extends StatelessWidget {
  const _ConfirmPage();

  @override
  Widget build(BuildContext context) {
    return SheetContentScaffold(
      appBar: _SharedAppBarHero(appbar: AppBar()),
      body: Padding(
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
                    groupValue: '',
                    onChanged: (_) {},
                  ),
                  const Divider(height: 32),
                  ListTile(
                    title: const Text('Seed tracks'),
                    trailing: IconButton(
                      onPressed: () =>
                          context.go('/intro/genre/mood/seed-track'),
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
      ),
      bottomBar: _BottomActionBar(
        label: "OK, let's go!",
        showDivider: true,
        onPressed: () async {
          context.go('/intro/genre/mood/seed-track/confirm/generate');
          await Future<void>.delayed(const Duration(seconds: 2));
          if (context.mounted) {
            context.go('/');
          }
        },
      ),
    );
  }
}

class _GeneratingPage extends StatelessWidget {
  const _GeneratingPage();

  @override
  Widget build(BuildContext context) {
    return SheetContentScaffold(
      appBar: _SharedAppBarHero(appbar: AppBar()),
      body: SafeArea(
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

final _largeFilledButtonStyle = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(56),
);

final _largeTextButtonStyle = TextButton.styleFrom(
  minimumSize: const Size.fromHeight(56),
);

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
            groupValue: selectedMood,
            onChanged: (newMooed) => setState(() {
              selectedMood = newMooed;
            }),
          ),
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.label,
    required this.onPressed,
    this.showDivider = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = 32.0;
    const verticalPadding = 16.0;

    // Insert bottom padding only if there's no system viewport bottom inset.
    final systemBottomInset = MediaQuery.of(context).padding.bottom;

    return StickyBottomBarVisibility(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDivider) const Divider(height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  systemBottomInset == 0 ? verticalPadding : 0,
                ),
                child: FilledButton(
                  onPressed: onPressed,
                  style: _largeFilledButtonStyle,
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// This widget makes it possible to create a (visually) shared appbar across the pages.
///
/// For better maintainability, it is recommended to create a page-specific app bar for each page
/// instead of a single 'super' shared app bar that includes all the functionality for every page.
class _SharedAppBarHero extends StatelessWidget implements PreferredSizeWidget {
  const _SharedAppBarHero({
    required this.appbar,
  });

  final AppBar appbar;

  @override
  Size get preferredSize => appbar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Hero(tag: 'HeroAppBar', child: appbar);
  }
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
