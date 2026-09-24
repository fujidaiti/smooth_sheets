import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

import 'src/flutter_test_x.dart';
import 'src/matchers.dart';

/// A motion the package does not ship, to prove [SheetMotion] is extensible.
class _GravityMotion extends SheetMotion {
  const _GravityMotion();

  @override
  Duration get duration => const Duration(milliseconds: 400);

  @override
  Curve get curve => Curves.linear;

  @override
  Simulation createSimulation({
    required double start,
    required double end,
    required double velocity,
  }) => GravitySimulation(9.8 * (end - start).sign, start, end, velocity);
}

class _Boilerplate extends StatelessWidget {
  const _Boilerplate({required this.modalRoute});

  final ModalSheetRoute<dynamic> modalRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, modalRoute),
                child: const Text('Open modal'),
              ),
            ),
          );
        },
      ),
    );
  }
}

ModalSheetRoute<dynamic> _createModalRoute({
  required SheetMotion transitionMotion,
  Duration transitionDuration = const Duration(milliseconds: 300),
  Curve transitionCurve = Curves.fastEaseInToSlowEaseOut,
  SwipeDismissSensitivity sensitivity = const SwipeDismissSensitivity(),
}) {
  return ModalSheetRoute<dynamic>(
    swipeDismissible: true,
    transitionMotion: transitionMotion,
    transitionDuration: transitionDuration,
    transitionCurve: transitionCurve,
    swipeDismissSensitivity: sensitivity,
    builder: (context) => Sheet(
      child: Container(
        key: const Key('sheet'),
        color: Colors.white,
        width: double.infinity,
        height: 600,
      ),
    ),
  );
}

/// Samples the transition progress of [route] once per [interval],
/// [sampleCount] times, without letting the animation settle in between.
Future<List<double>> _sampleTransition(
  WidgetTesterX tester,
  ModalSheetRoute<dynamic> route, {
  required int sampleCount,
  Duration interval = const Duration(milliseconds: 16),
}) async {
  final samples = <double>[];
  for (var i = 0; i < sampleCount; i++) {
    await tester.pump(interval);
    samples.add(route.animation!.value);
  }
  return samples;
}

void main() {
  group('$SpringSheetMotion', () {
    test('creates a simulation departing from start at the given velocity', () {
      const motion = SpringSheetMotion();
      final simulation = motion.createSimulation(
        start: 0.6,
        end: 1,
        velocity: -2.5,
      );

      expect(simulation.x(0), moreOrLessEquals(0.6));
      expect(simulation.dx(0), moreOrLessEquals(-2.5));
    });

    test('lands exactly on the end value once it is done', () {
      const motion = SpringSheetMotion();
      final simulation = motion.createSimulation(start: 0, end: 1, velocity: 0);

      var time = 0.0;
      while (!simulation.isDone(time) && time < 5) {
        time += 1 / 1000;
      }

      expect(
        time,
        lessThan(1),
        reason: 'The default spring should settle well within a second.',
      );
      expect(
        simulation.x(time),
        1.0,
        reason:
            'snapToEnd should place the animation exactly on the end value, '
            'since a spring only approaches it asymptotically.',
      );
      expect(simulation.dx(time), 0.0);
    });

    test('the default spring never overshoots either end', () {
      const motion = SpringSheetMotion();
      for (final velocity in [0.0, 2.5, 6.0]) {
        final opening = motion.createSimulation(
          start: 0,
          end: 1,
          velocity: velocity,
        );
        final closing = motion.createSimulation(
          start: 1,
          end: 0,
          velocity: -velocity,
        );
        for (var ms = 0; ms <= 1000; ms++) {
          expect(opening.x(ms / 1000), lessThanOrEqualTo(1.0));
          expect(closing.x(ms / 1000), greaterThanOrEqualTo(0.0));
        }
      }
    });

    test('the release velocity changes the trajectory', () {
      const motion = SpringSheetMotion();
      double positionAt100ms(double velocity) => motion
          .createSimulation(start: 0.6, end: 1, velocity: velocity)
          .x(0.1);

      final positions = [0.0, 2.5, 6.0].map(positionAt100ms).toList();

      expect(positions.toSet(), hasLength(3));
      expect(positions, isMonotonicallyIncreasing);
    });
  });

  group('$SpringSheetMotion iOS presets', () {
    // The natural frequency and damping ratio fully characterise a spring, and
    // SwiftUI's spring(duration:bounce:) is defined as a spring whose natural
    // period is `duration` and whose damping ratio is `1 - bounce`.
    double naturalPeriodOf(SpringDescription spring) =>
        2 * pi / sqrt(spring.stiffness / spring.mass);

    double dampingRatioOf(SpringDescription spring) =>
        spring.damping / (2 * sqrt(spring.mass * spring.stiffness));

    ({double peak, int settleMs}) simulate(
      SpringSheetMotion motion,
    ) {
      final simulation = motion.createSimulation(
        start: 0,
        end: 1,
        velocity: 0,
      );
      var peak = 0.0;
      var settleMs = 0;
      for (var ms = 0; ms <= 3000; ms++) {
        peak = max(peak, simulation.x(ms / 1000));
        if (settleMs == 0 && simulation.isDone(ms / 1000)) settleMs = ms;
      }
      return (peak: peak, settleMs: settleMs);
    }

    final presets =
        <String, ({SpringSheetMotion motion, int ms, double bounce})>{
          'smooth': (
            motion: SpringSheetMotion.smooth(),
            ms: 500,
            bounce: 0,
          ),
          'snappy': (
            motion: SpringSheetMotion.snappy(),
            ms: 500,
            bounce: 0.15,
          ),
          'bouncy': (
            motion: SpringSheetMotion.bouncy(),
            ms: 500,
            bounce: 0.3,
          ),
          'interactive': (
            motion: SpringSheetMotion.interactive(),
            ms: 150,
            bounce: 0.14,
          ),
        };

    presets.forEach((name, preset) {
      test('$name matches the iOS duration/bounce pair', () {
        final spring = preset.motion.spring;
        expect(
          naturalPeriodOf(spring),
          moreOrLessEquals(preset.ms / 1000, epsilon: 1e-9),
          reason: 'The natural period should equal the perceptual duration.',
        );
        expect(
          dampingRatioOf(spring),
          moreOrLessEquals(1 - preset.bounce, epsilon: 1e-9),
          reason: 'The damping ratio should equal 1 - bounce.',
        );
      });
    });

    test('only the bouncy presets overshoot', () {
      expect(simulate(presets['smooth']!.motion).peak, lessThanOrEqualTo(1.0));
      expect(simulate(presets['snappy']!.motion).peak, greaterThan(1.0));
      expect(simulate(presets['bouncy']!.motion).peak, greaterThan(1.0));
      expect(
        simulate(presets['bouncy']!.motion).peak,
        greaterThan(simulate(presets['snappy']!.motion).peak),
        reason: 'bouncy has more bounce than snappy, by definition.',
      );
    });

    test('interactive is much shorter than the others', () {
      expect(
        simulate(presets['interactive']!.motion).settleMs,
        lessThan(simulate(presets['smooth']!.motion).settleMs ~/ 2),
      );
    });

    test('extraBounce adds to the preset bounce', () {
      expect(
        dampingRatioOf(
          SpringSheetMotion.snappy(extraBounce: 0.15).spring,
        ),
        moreOrLessEquals(1 - 0.3, epsilon: 1e-9),
      );
    });
  });

  group('Deprecated transitionDuration and transitionCurve', () {
    test('still configure the motion of $ModalSheetRoute', () {
      final route = ModalSheetRoute<dynamic>(
        transitionDuration: const Duration(milliseconds: 450),
        transitionCurve: Curves.easeInOut,
        builder: (context) => const Sheet(child: SizedBox()),
      );

      expect(
        route.transitionMotion,
        isA<CurvedSheetMotion>()
            .having(
              (it) => it.duration,
              'duration',
              const Duration(milliseconds: 450),
            )
            .having((it) => it.curve, 'curve', Curves.easeInOut),
      );
      expect(route.transitionDuration, const Duration(milliseconds: 450));
      expect(route.transitionCurve, Curves.easeInOut);
    });

    test('still configure the motion of $CupertinoModalSheetRoute', () {
      final route = CupertinoModalSheetRoute<dynamic>(
        transitionDuration: const Duration(milliseconds: 450),
        transitionCurve: Curves.easeInOut,
        builder: (context) => const Sheet(child: SizedBox()),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 450));
      expect(route.transitionCurve, Curves.easeInOut);
    });

    test('are superseded by an explicit transitionMotion', () {
      final route = ModalSheetRoute<dynamic>(
        transitionDuration: const Duration(milliseconds: 450),
        transitionCurve: Curves.easeInOut,
        transitionMotion: const CurvedSheetMotion(
          duration: Duration(milliseconds: 800),
          curve: Curves.bounceIn,
        ),
        builder: (context) => const Sheet(child: SizedBox()),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 800));
      expect(route.transitionCurve, Curves.bounceIn);
    });

    test('report a nominal duration for a spring motion', () {
      final route = ModalSheetRoute<dynamic>(
        transitionDuration: const Duration(milliseconds: 450),
        transitionMotion: const SpringSheetMotion(),
        builder: (context) => const Sheet(child: SizedBox()),
      );

      expect(
        route.transitionDuration,
        const Duration(milliseconds: 300),
        reason:
            'A spring has no duration of its own, but ModalRoute demands one. '
            'It is never used to drive the animation.',
      );
      expect(route.transitionCurve, Curves.linear);
    });
  });

  group('$SheetMotion on a modal sheet route', () {
    testWidgets('defaults to $CurvedSheetMotion', (tester) async {
      final route = ModalSheetRoute<dynamic>(
        transitionCurve: Curves.easeInOut,
        builder: (context) => const Sheet(child: SizedBox(height: 100)),
      );
      await tester.pumpWidget(_Boilerplate(modalRoute: route));
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();

      expect(route.transitionMotion, isA<CurvedSheetMotion>());
      expect(route.effectiveCurve, Curves.easeInOut);
      expect(
        route.createSimulation(forward: true),
        isNull,
        reason:
            'A curve driven route must keep using the default, duration based '
            'animation of TransitionRoute.',
      );
    });

    testWidgets('reports a linear effective curve when driven by a spring', (
      tester,
    ) async {
      final route = _createModalRoute(
        transitionCurve: Curves.easeInOut,
        transitionMotion: const SheetMotion.spring(),
      );
      await tester.pumpWidget(_Boilerplate(modalRoute: route));
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();

      expect(
        route.effectiveCurve,
        Curves.linear,
        reason:
            'The simulation already describes the whole trajectory, so it must '
            'not be reshaped by transitionCurve.',
      );
    });

    testWidgets('the open transition follows the spring, '
        'not transitionDuration', (tester) async {
      const motion = SpringSheetMotion();
      final route = _createModalRoute(
        transitionMotion: motion,
        // Deliberately absurd: a spring settles when it runs out of energy,
        // so this must have no effect at all.
        transitionDuration: const Duration(seconds: 10),
      );
      await tester.pumpWidget(_Boilerplate(modalRoute: route));
      await tester.tap(find.text('Open modal'));
      await tester.pump();
      expect(route.animation!.value, 0.0);

      final expected = motion.createSimulation(start: 0, end: 1, velocity: 0);
      for (var frame = 1; frame <= 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          route.animation!.value,
          moreOrLessEquals(expected.x(frame * 16 / 1000), epsilon: 1e-6),
        );
      }

      await tester.pump(const Duration(milliseconds: 500));
      expect(route.animation!.isCompleted, isTrue);
      expect(route.animation!.value, 1.0);
    });

    testWidgets('is forwarded from $ModalSheetPage to its route', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            pages: const [
              MaterialPage<dynamic>(key: ValueKey('home'), child: SizedBox()),
              ModalSheetPage<dynamic>(
                key: ValueKey('modal'),
                transitionCurve: Curves.easeInOut,
                transitionMotion: SheetMotion.spring(),
                child: Sheet(child: SizedBox(key: Key('sheet'), height: 100)),
              ),
            ],
            onDidRemovePage: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final route =
          ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!
              as ModalSheetRouteMixin<dynamic>;
      expect(route.transitionMotion, isA<SpringSheetMotion>());
      expect(route.effectiveCurve, Curves.linear);
    });

    testWidgets('drives a $CupertinoModalSheetRoute as well', (tester) async {
      const motion = SpringSheetMotion();
      final route = CupertinoModalSheetRoute<dynamic>(
        transitionMotion: motion,
        transitionDuration: const Duration(seconds: 10),
        builder: (context) =>
            const Sheet(child: SizedBox(key: Key('sheet'), height: 300)),
      );

      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        CupertinoApp(
          navigatorKey: navigatorKey,
          home: const CupertinoPageScaffold(child: SizedBox()),
        ),
      );
      unawaited(navigatorKey.currentState!.push(route));
      await tester.pump();

      final expected = motion.createSimulation(start: 0, end: 1, velocity: 0);
      for (var frame = 1; frame <= 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          route.animation!.value,
          moreOrLessEquals(expected.x(frame * 16 / 1000), epsilon: 1e-6),
        );
      }

      await tester.pumpAndSettle();
      expect(route.animation!.value, 1.0);
    });

    testWidgets('lets a bouncy spring overshoot and settle back', (
      tester,
    ) async {
      final motion = SpringSheetMotion.bouncy();
      final route = _createModalRoute(transitionMotion: motion);
      await tester.pumpWidget(_Boilerplate(modalRoute: route));
      await tester.tap(find.text('Open modal'));
      await tester.pump();

      final samples = await _sampleTransition(
        tester,
        route,
        sampleCount: 60, // ~960ms, past the overshoot.
      );

      expect(
        samples.reduce(max),
        greaterThan(1.0),
        reason:
            'A bounded controller would clamp the overshoot away, pinning the '
            'sheet at the top until the spring came back into range.',
      );
      expect(
        samples.reduce(max),
        lessThan(1.1),
        reason: 'The overshoot of the bouncy preset is about 5%.',
      );

      await tester.pumpAndSettle();
      expect(route.animation!.value, 1.0);
      expect(route.animation!.isCompleted, isTrue);
    });

    testWidgets('settles a page that is added without a transition', (
      tester,
    ) async {
      // TransitionRoute.didAdd() jumps the controller to its upper bound and
      // relies on that to report AnimationStatus.completed. The upper bound of
      // the unbounded controller a spring needs is infinite, so both the value
      // and the status have to be restored by hand.
      var popped = false;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            pages: const [
              MaterialPage<dynamic>(key: ValueKey('home'), child: SizedBox()),
              ModalSheetPage<dynamic>(
                key: ValueKey('modal'),
                transitionMotion: SheetMotion.spring(),
                child: Sheet(child: SizedBox(key: Key('sheet'), height: 100)),
              ),
            ],
            onDidRemovePage: (_) => popped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final route =
          ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!
              as ModalSheetRouteMixin<dynamic>;
      expect(route.animation!.value, 1.0);
      expect(
        route.animation!.status,
        AnimationStatus.completed,
        reason:
            'A route that is added rather than pushed must report itself as '
            'settled, or barrier taps and drag routing both misbehave.',
      );

      // The barrier only dismisses a route whose animation is completed.
      await tester.tapAt(const Offset(400, 20));
      await tester.pumpAndSettle();
      expect(popped, isTrue);
    });

    testWidgets('keeps the motion it was installed with', (tester) async {
      // The controller is bounded for a curve and unbounded for a spring, so
      // the route must not observe a motion that changes underneath it: a
      // curve on an unbounded controller reverses towards negative infinity.
      final motion = ValueNotifier<SheetMotion>(
        const SheetMotion.spring(),
      );
      addTearDown(motion.dispose);

      await tester.pumpWidget(
        ValueListenableBuilder(
          valueListenable: motion,
          builder: (context, value, _) => Directionality(
            textDirection: TextDirection.ltr,
            child: Navigator(
              pages: [
                const MaterialPage<dynamic>(
                  key: ValueKey('home'),
                  child: SizedBox(),
                ),
                ModalSheetPage<dynamic>(
                  key: const ValueKey('modal'),
                  transitionMotion: value,
                  child: const Sheet(
                    child: SizedBox(key: Key('sheet'), height: 100),
                  ),
                ),
              ],
              onDidRemovePage: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final route =
          ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!
              as ModalSheetRouteMixin<dynamic>;

      motion.value = const CurvedSheetMotion();
      await tester.pumpAndSettle();
      expect(route.transitionMotion, isA<CurvedSheetMotion>());

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        route.animation!.value,
        inInclusiveRange(0.0, 1.0),
        reason:
            'The pop must keep using the spring the controller was built for.',
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sheet')), findsNothing);
    });

    testWidgets('the close transition follows the spring', (tester) async {
      const motion = SpringSheetMotion();
      final route = _createModalRoute(transitionMotion: motion);
      await tester.pumpWidget(_Boilerplate(modalRoute: route));
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pump();

      final expected = motion.createSimulation(start: 1, end: 0, velocity: 0);
      for (var frame = 1; frame <= 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          route.animation!.value,
          moreOrLessEquals(expected.x(frame * 16 / 1000), epsilon: 1e-6),
        );
      }

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sheet')), findsNothing);
    });
  });

  group('Swipe-to-dismiss release velocity', () {
    /// Opens a modal, drags it down by 100px releasing at [flingSpeed],
    /// and returns the transition progress of each of the next 20 frames.
    ///
    /// The sensitivity is configured so that the gesture never dismisses the
    /// modal, which makes every sample part of the settle-back animation.
    Future<List<double>> settleBackTrajectory(
      WidgetTesterX tester, {
      required SheetMotion motion,
      required double flingSpeed,
    }) async {
      final route = _createModalRoute(
        transitionMotion: motion,
        sensitivity: const SwipeDismissSensitivity(
          minFlingVelocityRatio: 100,
          dismissalOffset: SheetOffset.absolute(0),
        ),
      );

      await tester.pumpWidget(_Boilerplate(modalRoute: route));
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();

      await tester.fling(
        find.byKey(const Key('sheet')),
        const Offset(0, 100),
        flingSpeed,
      );
      final samples = await _sampleTransition(tester, route, sampleCount: 20);

      await tester.pumpAndSettle();
      expect(
        route.animation!.value,
        1.0,
        reason: 'The modal should have settled back to its original position.',
      );
      // Tear the tree down so that the next scenario starts from scratch.
      await tester.pumpWidget(const SizedBox.shrink());
      return samples;
    }

    testWidgets('is thrown away by a curve driven transition', (tester) async {
      const motion = CurvedSheetMotion();
      final gentle = await settleBackTrajectory(
        tester,
        motion: motion,
        flingSpeed: 200,
      );
      final hard = await settleBackTrajectory(
        tester,
        motion: motion,
        flingSpeed: 4000,
      );

      expect(
        hard,
        orderedEquals(gentle),
        reason:
            'A curve is a pure function of elapsed time, so a flick and a slow '
            'release produce byte-for-byte identical motion.',
      );
    });

    testWidgets('is carried into a spring driven transition', (tester) async {
      const motion = SpringSheetMotion();
      final gentle = await settleBackTrajectory(
        tester,
        motion: motion,
        flingSpeed: 200,
      );
      final hard = await settleBackTrajectory(
        tester,
        motion: motion,
        flingSpeed: 4000,
      );

      expect(hard, isNot(orderedEquals(gentle)));
      expect(
        hard.reduce(min),
        lessThan(gentle.reduce(min)),
        reason:
            'The harder the sheet is flung downwards, the further it keeps '
            'travelling before the spring pulls it back.',
      );
      expect(
        hard.last,
        greaterThan(hard.reduce(min)),
        reason: 'The spring must bring the sheet back up afterwards.',
      );
    });
  });

  group('showModalSheet helpers', () {
    Future<ModalSheetRouteMixin<dynamic>> open(
      WidgetTesterX tester,
      Future<void> Function(BuildContext context) show,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => show(context),
              child: const Text('Open modal'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      return ModalRoute.of(tester.element(find.byKey(const Key('sheet'))))!
          as ModalSheetRouteMixin<dynamic>;
    }

    const sheet = Sheet(child: SizedBox(key: Key('sheet'), height: 100));

    testWidgets('showModalSheet forwards transitionMotion', (tester) async {
      final route = await open(
        tester,
        (context) => showModalSheet<void>(
          context: context,
          transitionMotion: const SheetMotion.spring(),
          builder: (context) => sheet,
        ),
      );
      expect(route.transitionMotion, isA<SpringSheetMotion>());
    });

    testWidgets('showCupertinoModalSheet forwards transitionMotion', (
      tester,
    ) async {
      final route = await open(
        tester,
        (context) => showCupertinoModalSheet<void>(
          context: context,
          transitionMotion: SpringSheetMotion.bouncy(),
          builder: (context) => sheet,
        ),
      );
      expect(route.transitionMotion, isA<SpringSheetMotion>());
    });

    testWidgets('showAdaptiveModalSheet forwards transitionMotion', (
      tester,
    ) async {
      final route = await open(
        tester,
        (context) => showAdaptiveModalSheet<void>(
          context: context,
          transitionMotion: const SheetMotion.spring(),
          builder: (context) => sheet,
        ),
      );
      expect(route.transitionMotion, isA<SpringSheetMotion>());
    });

    testWidgets('still honour the deprecated duration and curve', (
      tester,
    ) async {
      final route = await open(
        tester,
        (context) => showModalSheet<void>(
          context: context,
          transitionDuration: const Duration(milliseconds: 450),
          transitionCurve: Curves.easeInOut,
          builder: (context) => sheet,
        ),
      );
      expect(route.transitionDuration, const Duration(milliseconds: 450));
      expect(route.transitionCurve, Curves.easeInOut);
    });
  });

  group('Dismissal fling velocity', () {
    /// Opens a modal, flings it away at [flingSpeed], and returns the
    /// transition progress of each of the next 6 frames of the pop animation.
    Future<List<double>> dismissTrajectory(
      WidgetTesterX tester, {
      required SheetMotion motion,
      required double flingSpeed,
    }) async {
      final route = _createModalRoute(
        transitionMotion: motion,
        sensitivity: const SwipeDismissSensitivity(
          minFlingVelocityRatio: 1,
          dismissalOffset: SheetOffset.absolute(0),
        ),
      );

      await tester.pumpWidget(_Boilerplate(modalRoute: route));
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();

      await tester.fling(
        find.byKey(const Key('sheet')),
        const Offset(0, 100),
        flingSpeed,
      );
      final samples = await _sampleTransition(tester, route, sampleCount: 6);

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sheet')), findsNothing);
      // Tear the tree down so that the next scenario starts from scratch.
      await tester.pumpWidget(const SizedBox.shrink());
      return samples;
    }

    testWidgets('is thrown away by a curve driven pop', (tester) async {
      const motion = CurvedSheetMotion();
      final gentle = await dismissTrajectory(
        tester,
        motion: motion,
        flingSpeed: 1000,
      );
      final hard = await dismissTrajectory(
        tester,
        motion: motion,
        flingSpeed: 6000,
      );

      expect(hard, orderedEquals(gentle));
    });

    testWidgets('is carried into a spring driven pop', (tester) async {
      const motion = SpringSheetMotion();
      final gentle = await dismissTrajectory(
        tester,
        motion: motion,
        flingSpeed: 1000,
      );
      final hard = await dismissTrajectory(
        tester,
        motion: motion,
        flingSpeed: 6000,
      );

      for (var i = 0; i < gentle.length; i++) {
        expect(
          hard[i],
          lessThan(gentle[i]),
          reason:
              'The release velocity is handed to the pop simulation, so at '
              'every moment the harder fling must be further on its way out.',
        );
      }
    });
  });

  group('$SheetController.animateTo', () {
    ({Widget widget, SheetController controller}) boilerplate() {
      final controller = SheetController();
      return (
        widget: MaterialApp(
          home: SheetViewport(
            child: Sheet(
              controller: controller,
              snapGrid: const SheetSnapGrid(
                snaps: [SheetOffset(0.5), SheetOffset(1)],
              ),
              child: Container(
                key: const Key('sheet'),
                color: const Color(0xFFFFFFFF),
                height: 600,
              ),
            ),
          ),
        ),
        controller: controller,
      );
    }

    testWidgets('defaults to the motion animateTo has always used', (
      tester,
    ) async {
      // Migrating `duration:` to `CurvedSheetMotion(duration:)` must not
      // silently change the easing: animateTo has always used easeInOut,
      // while CurvedSheetMotion itself defaults to fastEaseInToSlowEaseOut.
      Future<List<double>> trajectory(SheetMotion? motion) async {
        final env = boilerplate();
        addTearDown(env.controller.dispose);
        await tester.pumpWidget(env.widget);
        await tester.pumpAndSettle();

        unawaited(
          env.controller.animateTo(const SheetOffset(0.5), motion: motion),
        );
        await tester.pump();

        final samples = <double>[];
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          samples.add(env.controller.value!);
        }
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        return samples;
      }

      final byDefault = await trajectory(null);
      final explicit = await trajectory(kDefaultSheetAnimationMotion);
      expect(byDefault, orderedEquals(explicit));

      final differentCurve = await trajectory(const CurvedSheetMotion());
      expect(
        differentCurve,
        isNot(orderedEquals(byDefault)),
        reason:
            'CurvedSheetMotion() is NOT the animateTo default. If these ever '
            'match, the trap this constant exists to document is gone and '
            'the constant can go too.',
      );
    });

    testWidgets('moves the sheet with a spring motion', (tester) async {
      final env = boilerplate();
      addTearDown(env.controller.dispose);
      await tester.pumpWidget(env.widget);
      await tester.pumpAndSettle();

      final start = env.controller.value!;
      unawaited(
        env.controller.animateTo(
          const SheetOffset(0.5),
          motion: const SpringSheetMotion(),
        ),
      );
      await tester.pump();

      final samples = <double>[];
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        samples.add(env.controller.value!);
      }
      expect(samples, isMonotonicallyDecreasing);
      expect(samples.last, lessThan(start));

      await tester.pumpAndSettle();
      expect(env.controller.value, moreOrLessEquals(300, epsilon: 0.5));
    });

    testWidgets('a bouncy motion overshoots and settles back', (tester) async {
      final env = boilerplate();
      addTearDown(env.controller.dispose);
      await tester.pumpWidget(env.widget);
      await tester.pumpAndSettle();

      unawaited(
        env.controller.animateTo(
          const SheetOffset(0.5),
          motion: SpringSheetMotion.bouncy(),
        ),
      );
      await tester.pump();

      var lowest = double.infinity;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        lowest = min(lowest, env.controller.value!);
      }
      expect(
        lowest,
        lessThan(300),
        reason: 'A bouncy spring travels past its destination first.',
      );

      await tester.pumpAndSettle();
      expect(env.controller.value, moreOrLessEquals(300, epsilon: 0.5));
    });

    testWidgets('completes its future and comes to rest', (tester) async {
      final env = boilerplate();
      addTearDown(env.controller.dispose);
      await tester.pumpWidget(env.widget);
      await tester.pumpAndSettle();

      var done = false;
      unawaited(
        env.controller
            .animateTo(
              const SheetOffset(0.5),
              motion: const SpringSheetMotion(),
            )
            .whenComplete(() => done = true),
      );
      await tester.pumpAndSettle();

      expect(done, isTrue);
      expect(env.controller.value, moreOrLessEquals(300, epsilon: 0.5));
    });
  });

  group('SheetMotion is unit agnostic', () {
    // This is the load-bearing property of reusing one motion type for both
    // route transitions and animateTo: a SheetMotion always describes a
    // normalized 0 to 1 progress, so its Tolerance is in progress units and
    // the motion takes the same time whatever distance it is mapped onto.
    //
    // Applying the same spring directly in pixel space would not be: the
    // tolerance is compared against the remaining distance in the caller's
    // own units, so the settle time would drift with the distance.
    int framesToSettle(Simulation simulation) {
      var frames = 0;
      while (frames < 600 && !simulation.isDone(frames * 16 / 1000)) {
        frames++;
      }
      return frames;
    }

    testWidgets('moves any distance in the same time', (tester) async {
      // The consumer maps the normalized progress onto whatever distance it
      // needs, so the settle time must not depend on that distance. Measured
      // end to end rather than on the simulation, since it is the consumer
      // that does the normalizing.
      Future<int> framesToArrive(double sheetHeight) async {
        final controller = SheetController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: SheetViewport(
              child: Sheet(
                controller: controller,
                snapGrid: const SheetSnapGrid(
                  snaps: [SheetOffset(0), SheetOffset(1)],
                ),
                child: SizedBox(height: sheetHeight, width: double.infinity),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final future = controller.animateTo(
          const SheetOffset(0),
          motion: const SpringSheetMotion(),
        );
        await tester.pump();

        var frames = 0;
        var done = false;
        unawaited(future.whenComplete(() => done = true));
        while (frames < 600 && !done) {
          await tester.pump(const Duration(milliseconds: 16));
          frames++;
        }
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        return frames;
      }

      final short = await framesToArrive(120);
      final long = await framesToArrive(560);
      expect(
        long,
        short,
        reason:
            'A SheetMotion describes a normalized 0 to 1 progress, so a '
            '560px move must take exactly as long as a 120px one. Handing '
            'the spring pixels instead would make the longer move settle '
            'later, because Tolerance is measured in the caller units.',
      );
    });

    test('a pixel space spring would drift with the distance', () {
      const motion = SpringSheetMotion();
      final short = framesToSettle(
        SpringSimulation(
          motion.spring,
          0,
          100,
          0,
          tolerance: motion.tolerance,
          snapToEnd: true,
        ),
      );
      final long = framesToSettle(
        SpringSimulation(
          motion.spring,
          0,
          900,
          0,
          tolerance: motion.tolerance,
          snapToEnd: true,
        ),
      );

      expect(
        long,
        greaterThan(short),
        reason:
            'Tolerance.distance is compared against the remaining distance in '
            'the caller units, so a longer travel takes longer to settle. '
            'This is why the motion is normalized before it reaches the '
            'simulation.',
      );
    });
  });

  group('Reduced motion', () {
    // AnimationController applies its own scaling to duration driven
    // animations when the platform asks for animations to be disabled, but
    // not to simulation driven ones, so the spring paths have to do it
    // themselves.
    void disableAnimations(WidgetTesterX tester) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }

    testWidgets('shortens a spring driven route transition', (tester) async {
      disableAnimations(tester);

      final route = _createModalRoute(
        transitionMotion: const SpringSheetMotion(),
      );
      await tester.pumpWidget(_Boilerplate(modalRoute: route));
      await tester.tap(find.text('Open modal'));
      await tester.pump();

      // The default spring settles in ~405ms, so at 5% of that it must
      // already be done well inside a couple of frames.
      await tester.pump(const Duration(milliseconds: 32));
      expect(
        route.animation!.value,
        1.0,
        reason: 'A disabled animation should be over almost immediately.',
      );
      expect(route.animation!.isCompleted, isTrue);
    });

    testWidgets('shortens a spring driven animateTo', (tester) async {
      disableAnimations(tester);

      final controller = SheetController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SheetViewport(
            child: Sheet(
              controller: controller,
              snapGrid: const SheetSnapGrid(
                snaps: [SheetOffset(0.5), SheetOffset(1)],
              ),
              child: Container(
                key: const Key('sheet'),
                color: const Color(0xFFFFFFFF),
                height: 600,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      unawaited(
        controller.animateTo(
          const SheetOffset(0.5),
          motion: const SpringSheetMotion(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));

      expect(controller.value, moreOrLessEquals(300, epsilon: 1));
    });
  });

  group('Spring driven route with a draggable sheet', () {
    Widget boilerplate(SheetMotion motion) => Directionality(
      textDirection: TextDirection.ltr,
      child: Navigator(
        pages: [
          const MaterialPage<dynamic>(key: ValueKey('home'), child: SizedBox()),
          ModalSheetPage<dynamic>(
            key: const ValueKey('modal'),
            swipeDismissible: true,
            transitionMotion: motion,
            child: Sheet(
              initialOffset: const SheetOffset(1),
              snapGrid: const SheetSnapGrid(
                snaps: [SheetOffset(0.5), SheetOffset(1)],
              ),
              child: Container(
                key: const Key('sheet'),
                color: const Color(0xFFFFFFFF),
                height: 500,
              ),
            ),
          ),
        ],
        onDidRemovePage: (_) {},
      ),
    );

    // The drag routing in _SheetDismissible asks whether the route transition
    // has settled. Reading that off the raw controller does not work for a
    // spring, because an unbounded controller cannot derive completed from
    // its infinite bounds — so every drag was booked as route dismissal
    // progress and the sheet could never reach an intermediate snap.
    for (final entry in {
      'a curve': const CurvedSheetMotion(),
      'a spring': const SpringSheetMotion(),
    }.entries) {
      testWidgets('lets the sheet settle at its own snap with ${entry.key}', (
        tester,
      ) async {
        await tester.pumpWidget(boilerplate(entry.value));
        await tester.pumpAndSettle();
        final top = tester.getRect(find.byKey(const Key('sheet'))).top;

        await tester.drag(find.byKey(const Key('sheet')), const Offset(0, 200));
        await tester.pumpAndSettle();

        expect(
          tester.getRect(find.byKey(const Key('sheet'))).top,
          greaterThan(top),
          reason:
              'The drag belongs to the sheet, which should come to rest at '
              'its lower snap rather than dragging the whole route.',
        );
        expect(find.byKey(const Key('sheet')), findsOneWidget);
      });
    }

    testWidgets('survives a drag started during a bouncy overshoot', (
      tester,
    ) async {
      final route = ModalSheetRoute<void>(
        swipeDismissible: true,
        transitionMotion: SpringSheetMotion.bouncy(),
        builder: (context) => Sheet(
          initialOffset: const SheetOffset(1),
          snapGrid: const SheetSnapGrid(
            snaps: [SheetOffset(0.5), SheetOffset(1)],
          ),
          child: Container(
            key: const Key('sheet'),
            color: const Color(0xFFFFFFFF),
            height: 500,
          ),
        ),
      );
      await tester.pumpWidget(_Boilerplate(modalRoute: route));
      await tester.tap(find.text('Open modal'));
      await tester.pump();

      // Advance to a frame where the spring is past its destination.
      var frames = 0;
      while (frames < 120 && route.animation!.value <= 1.0) {
        await tester.pump(const Duration(milliseconds: 16));
        frames++;
      }
      expect(
        route.animation!.value,
        greaterThan(1.0),
        reason: 'The test needs to catch the sheet mid-overshoot.',
      );

      // Grabbing the sheet here used to trip an assertion, because the
      // transition progress was above 1 and the drag handler assumed it
      // could not be.
      final gesture = await tester.press(find.byKey(const Key('sheet')));
      await gesture.moveBy(const Offset(0, 40));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('A user defined $SheetMotion', () {
    testWidgets('can drive a route transition', (tester) async {
      final route = ModalSheetRoute<void>(
        transitionMotion: const _GravityMotion(),
        builder: (_) =>
            const Sheet(child: SizedBox(key: Key('sheet'), height: 200)),
      );
      await tester.pumpWidget(_Boilerplate(modalRoute: route));
      await tester.tap(find.text('Open modal'));
      await tester.pump();

      final expected = const _GravityMotion().createSimulation(
        start: 0,
        end: 1,
        velocity: 0,
      );
      for (var frame = 1; frame <= 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          route.animation!.value,
          moreOrLessEquals(expected.x(frame * 16 / 1000), epsilon: 1e-6),
        );
      }

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sheet')), findsOneWidget);
    });

    testWidgets('can drive animateTo', (tester) async {
      final controller = SheetController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SheetViewport(
            child: Sheet(
              controller: controller,
              snapGrid: const SheetSnapGrid(
                snaps: [SheetOffset(0.5), SheetOffset(1)],
              ),
              child: Container(
                key: const Key('sheet'),
                color: const Color(0xFFFFFFFF),
                height: 600,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must not be awaited before pumping: the future only completes once
      // frames run.
      unawaited(
        controller.animateTo(
          const SheetOffset(0.5),
          motion: const _GravityMotion(),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.value, moreOrLessEquals(300, epsilon: 0.5));
    });
  });
}
