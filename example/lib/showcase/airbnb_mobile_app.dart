import 'package:faker/faker.dart' hide Image, Color;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock the screen orientation to portrait.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const _AirbnbMobileAppExample());
}

class _AirbnbMobileAppExample extends StatelessWidget {
  const _AirbnbMobileAppExample();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false),
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    // Cache the system UI insets outside of the scaffold for later use.
    // This is because the scaffold adds the height of the navigation bar
    // to the padding.bottom of the inherited MediaQuery and re-exposes it
    // to the descendant widgets. Therefore, the descendant widgets cannot get
    // the net system UI insets.
    final systemUiInsets = MediaQuery.of(context).padding;

    final result = Scaffold(
      // Enable this flag since the navigation bar
      // will be hidden when the sheet is dragged down.
      extendBody: true,
      // Enable this flag since we want the sheet handle to be drawn
      // behind the tab bar when the sheet is fully expanded.
      extendBodyBehindAppBar: true,
      appBar: const _AppBar(),
      body: Stack(
        children: [
          const _Map(),
          _ContentSheet(systemUiInsets: systemUiInsets),
        ],
      ),
      bottomNavigationBar: const _BottomNavigationBar(),
      floatingActionButton: const _MapButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );

    return DefaultTabController(
      length: _AppBar.tabs.length,
      // Provides a SheetController to the descendant widgets
      // to perform some sheet position driven animations.
      // The sheet will look up and use this controller unless
      // another one is manually specified in the constructor.
      // The descendant widgets can also get this controller by
      // calling 'DefaultSheetController.of(context)'.
      child: DefaultSheetController(
        child: result,
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton();

  @override
  Widget build(BuildContext context) {
    final sheetController = DefaultSheetController.of(context);

    void onPressed() {
      if (sheetController.metrics case final it?) {
        // Collapse the sheet to reveal the map behind.
        sheetController.animateTo(
          SheetOffset.absolute(it.minOffset),
          curve: Curves.fastOutSlowIn,
        );
      }
    }

    final result = FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: Colors.black,
      label: const Text('Map'),
      icon: const Icon(Icons.map),
    );

    // It is easy to create sheet position driven animations
    // by using 'PositionDrivenAnimation', a special kind of
    // 'Animation<double>' whose value changes from 0 to 1 as
    // the sheet position changes from 'startPosition' to 'endPosition'.
    final animation = SheetOffsetDrivenAnimation(
      controller: DefaultSheetController.of(context),
      // The initial value of the animation is required
      // since the sheet position is not available at the first build.
      initialValue: 1,
      // If null, the minimum position will be used. (Default)
      startOffset: null,
      // If null, the maximum position will be used. (Default)
      endOffset: null,
    ).drive(CurveTween(curve: Curves.easeInExpo));

    // Hide the button when the sheet is dragged down.
    return ScaleTransition(
      scale: animation,
      child: FadeTransition(
        opacity: animation,
        child: result,
      ),
    );
  }
}

class _Map extends StatelessWidget {
  const _Map();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox.expand(
        child: Image.asset(
          'assets/fake_map.png',
          fit: BoxFit.fitHeight,
        ),
      ),
    );
  }
}

class _ContentSheet extends StatelessWidget {
  const _ContentSheet({
    required this.systemUiInsets,
  });

  final EdgeInsets systemUiInsets;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentHeight = constraints.maxHeight;
        final appbarHeight = MediaQuery.of(context).padding.top;
        final handleHeight = const _ContentSheetHandle().preferredSize.height;
        final sheetHeight = parentHeight - appbarHeight + handleHeight;
        final minSheetOffset =
            SheetOffset.absolute(handleHeight + systemUiInsets.bottom);

        return SheetViewport(
          child: Sheet(
            scrollConfiguration: const SheetScrollConfiguration(),
            snapGrid: SheetSnapGrid(
              snaps: [minSheetOffset, const SheetOffset(1)],
            ),
            decoration: const MaterialSheetDecoration(
              size: SheetSize.fit,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
            ),
            child: SizedBox(
              height: sheetHeight,
              child: const Column(
                children: [
                  _ContentSheetHandle(),
                  Expanded(child: _HouseList()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContentSheetHandle extends StatelessWidget
    implements PreferredSizeWidget {
  const _ContentSheetHandle();

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: preferredSize,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            buildIndicator(),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text(
                  '646 national park homes',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIndicator() {
    return Container(
      height: 6,
      width: 40,
      decoration: const ShapeDecoration(
        color: Colors.black12,
        shape: StadiumBorder(),
      ),
    );
  }
}

class _HouseList extends StatelessWidget {
  const _HouseList();

  @override
  Widget build(BuildContext context) {
    final result = ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      itemCount: _houses.length,
      itemBuilder: (context, index) {
        return _HouseCard(_houses[index]);
      },
    );

    // Hide the list when the sheet is dragged down.
    return FadeTransition(
      opacity: SheetOffsetDrivenAnimation(
        controller: DefaultSheetController.of(context),
        initialValue: 1,
      ).drive(
        CurveTween(curve: Curves.easeOutCubic),
      ),
      child: result,
    );
  }
}

class _House {
  const _House({
    required this.title,
    required this.rating,
    required this.distance,
    required this.charge,
    required this.image,
  });

  factory _House.random() {
    return _House(
      title: '${faker.address.city()}, ${faker.address.country()}',
      rating: faker.randomGenerator.decimal(scale: 1.5, min: 3.5),
      distance: faker.randomGenerator.integer(300, min: 50),
      charge: faker.randomGenerator.integer(2000, min: 500),
      image: faker.image.loremPicsum(width: 300, height: 300),
    );
  }

  final String title;
  final double rating;
  final int distance;
  final int charge;
  final String image;
}

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();

  static const tabs = [
    Tab(text: 'National parks', icon: Icon(Icons.forest_outlined)),
    Tab(text: 'Tiny homes', icon: Icon(Icons.cabin_outlined)),
    Tab(text: 'Ryokan', icon: Icon(Icons.hotel_outlined)),
    Tab(text: 'Play', icon: Icon(Icons.celebration_outlined)),
  ];

  static const topHeight = 90.0;

  // The tab bar height is defined in:
  // https://github.com/flutter/flutter/blob/78666c8dc57e9f7548ca9f8dd0740fbf0c658dc9/packages/flutter/lib/src/material/tabs.dart#L29
  static const bottomHeight = 72.0;

  @override
  Size get preferredSize => const Size.fromHeight(topHeight + bottomHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      toolbarHeight: topHeight,
      title: buildToolBar(context),
      bottom: buildTabBar(),
    );
  }

  PreferredSizeWidget buildTabBar() {
    return const TabBar(
      tabs: tabs,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.black54,
      indicatorColor: Colors.black,
    );
  }

  Widget buildToolBar(BuildContext context) {
    return SizedBox(
      height: topHeight,
      child: Row(
        children: [
          Expanded(child: buildSearchBox(context)),
          const SizedBox(width: 16),
          buildFilterButton(context),
        ],
      ),
    );
  }

  Widget buildSearchBox(BuildContext context) {
    final inputArea = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where to?',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Anywhere · Any week · Add guest',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: Colors.black54),
        ),
      ],
    );

    const decoration = ShapeDecoration(
      color: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: Colors.black12),
      ),
      shadows: [
        BoxShadow(
          color: Color(0x0a000000),
          spreadRadius: 4,
          blurRadius: 8,
          offset: Offset(1, 1),
        ),
      ],
    );

    return Container(
      height: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: decoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.search, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(child: inputArea),
        ],
      ),
    );
  }

  Widget buildFilterButton(BuildContext context) {
    return IconButton(
      onPressed: () {},
      color: Colors.black,
      icon: const Icon(Icons.tune_outlined),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar();

  @override
  Widget build(BuildContext context) {
    final result = BottomNavigationBar(
      unselectedItemColor: Colors.black54,
      selectedItemColor: Colors.pink,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border_outlined),
          label: 'Wishlists',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.luggage_outlined),
          label: 'Trips',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inbox_outlined),
          label: 'Inbox',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );

    // Hide the navigation bar when the sheet is dragged down.
    return SlideTransition(
      position: SheetOffsetDrivenAnimation(
        controller: DefaultSheetController.of(context),
        initialValue: 1,
      ).drive(
        Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ),
      ),
      child: result,
    );
  }
}

class _HouseCard extends StatelessWidget {
  const _HouseCard(this.house);

  final _House house;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryTextStyle =
        textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final secondaryTextStyle = textTheme.titleMedium;
    final tertiaryTextStyle =
        textTheme.titleMedium?.copyWith(color: Colors.black54);

    final image = Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Image.network(
          house.image,
          fit: BoxFit.fitWidth,
        ),
      ),
    );

    final rating = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: secondaryTextStyle?.color, size: 18),
        const SizedBox(width: 4),
        Text(house.rating.toStringAsFixed(1), style: secondaryTextStyle),
      ],
    );

    final heading = Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            house.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: primaryTextStyle,
          ),
        ),
        const SizedBox(width: 8),
        rating,
      ],
    );

    final description = [
      Text('${house.distance} kilometers away', style: tertiaryTextStyle),
      const SizedBox(height: 4),
      Text('5 nights · Jan 14 - 19', style: tertiaryTextStyle),
      const SizedBox(height: 16),
      Text(
        '\$${house.charge} total before taxes',
        style: secondaryTextStyle?.copyWith(
          decoration: TextDecoration.underline,
        ),
      ),
    ];

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            image,
            const SizedBox(height: 16),
            heading,
            const SizedBox(height: 8),
            ...description,
          ],
        ),
      ),
    );
  }
}

final _houses = List.generate(50, (_) => _House.random());
