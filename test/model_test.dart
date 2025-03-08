import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_sheets/src/model.dart';

void main() {
  test('ImmutableSheetMetrics.copyWith', () {
    final original = ImmutableSheetMetrics(
      offset: 300,
      minOffset: 100,
      maxOffset: 500,
      devicePixelRatio: 2,
      contentBaseline: 20,
      contentSize: Size(300, 400),
      size: Size(300, 500),
      viewportDynamicOverlap: EdgeInsets.only(bottom: 200),
      viewportPadding: EdgeInsets.symmetric(horizontal: 20),
      viewportSize: Size(400, 800),
      viewportStaticOverlap: EdgeInsets.only(top: 50),
    );

    final copy = original.copyWith(
      offset: 400,
      minOffset: 150,
      maxOffset: 550,
      devicePixelRatio: 2.5,
      contentBaseline: 25,
      contentSize: Size(350, 450),
      size: Size(350, 550),
      viewportDynamicOverlap: EdgeInsets.only(bottom: 250),
      viewportPadding: EdgeInsets.symmetric(horizontal: 25),
      viewportSize: Size(450, 850),
      viewportStaticOverlap: EdgeInsets.only(top: 55),
    );

    expect(copy.offset, 400);
    expect(copy.minOffset, 150);
    expect(copy.maxOffset, 550);
    expect(copy.devicePixelRatio, 2.5);
    expect(copy.contentBaseline, 25);
    expect(copy.contentSize, Size(350, 450));
    expect(copy.size, Size(350, 550));
    expect(copy.viewportDynamicOverlap, EdgeInsets.only(bottom: 250));
    expect(copy.viewportPadding, EdgeInsets.symmetric(horizontal: 25));
    expect(copy.viewportSize, Size(450, 850));
    expect(copy.viewportStaticOverlap, EdgeInsets.only(top: 55));
  });

  group('SheetMetrics', () {
    test('rect - without padding', () {
      expect(
        _TestSheetMetrics(
          offset: 300,
          size: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).rect,
        Rect.fromLTWH(0, 500, 400, 300),
      );
      expect(
        _TestSheetMetrics(
          offset: 350,
          size: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).rect,
        Rect.fromLTWH(0, 450, 400, 300),
      );
    });

    test('rect - with padding', () {
      expect(
        _TestSheetMetrics(
          offset: 320,
          size: Size(360, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.all(20),
        ).rect,
        Rect.fromLTWH(20, 480, 360, 300),
      );
      expect(
        _TestSheetMetrics(
          offset: 350,
          size: Size(360, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.all(20),
        ).rect,
        Rect.fromLTWH(20, 450, 360, 300),
      );
    });

    test('rect - when sheet is outside of viewport', () {
      expect(
        _TestSheetMetrics(
          offset: -100,
          size: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).rect,
        Rect.fromLTWH(0, 900, 400, 300),
      );

      expect(
        _TestSheetMetrics(
          offset: 1200,
          size: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).rect,
        Rect.fromLTWH(0, -400, 400, 300),
      );
    });

    test('visibleRect - when sheet is fully visible', () {
      expect(
        _TestSheetMetrics(
          offset: 300,
          size: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).visibleRect,
        Rect.fromLTWH(0, 500, 400, 300),
      );
    });

    test('visibleRect - when sheet is partially visible at the top', () {
      expect(
        _TestSheetMetrics(
          offset: 900,
          size: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).visibleRect,
        Rect.fromLTWH(0, 0, 400, 200),
      );
    });

    test('visibleRect - when sheet is partially visible at the bottom', () {
      expect(
        _TestSheetMetrics(
          offset: 100,
          size: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).visibleRect,
        Rect.fromLTWH(0, 700, 400, 100),
      );
    });

    test('visibleRect - when sheet is not visible', () {
      expect(
        _TestSheetMetrics(
          offset: 1200,
          size: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).visibleRect,
        null,
      );
    });

    test('contentRect - without padding', () {
      expect(
        _TestSheetMetrics(
          offset: 300,
          size: Size(400, 300),
          contentSize: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).contentRect,
        Rect.fromLTWH(0, 500, 400, 300),
      );
      expect(
        _TestSheetMetrics(
          offset: 350,
          size: Size(400, 300),
          contentSize: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).contentRect,
        Rect.fromLTWH(0, 450, 400, 300),
      );
    });

    test('contentRect - with padding', () {
      expect(
        _TestSheetMetrics(
          offset: 320,
          size: Size(360, 300),
          contentSize: Size(360, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.all(20),
        ).contentRect,
        Rect.fromLTWH(20, 480, 360, 300),
      );
      expect(
        _TestSheetMetrics(
          offset: 350,
          size: Size(360, 300),
          contentSize: Size(360, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.all(20),
        ).contentRect,
        Rect.fromLTWH(20, 450, 360, 300),
      );
    });

    test('contentRect - when content is outside of viewport', () {
      expect(
        _TestSheetMetrics(
          offset: -100,
          size: Size(400, 300),
          contentSize: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).contentRect,
        Rect.fromLTWH(0, 900, 400, 300),
      );

      expect(
        _TestSheetMetrics(
          offset: 1200,
          size: Size(400, 300),
          contentSize: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).contentRect,
        Rect.fromLTWH(0, -400, 400, 300),
      );
    });

    test('visibleContentRect - when content is fully visible', () {
      expect(
        _TestSheetMetrics(
          offset: 300,
          size: Size(400, 300),
          contentSize: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).visibleContentRect,
        Rect.fromLTWH(0, 500, 400, 300),
      );
    });

    test('visibleContentRect - when content is partially visible at the top',
        () {
      expect(
        _TestSheetMetrics(
          offset: 900,
          size: Size(400, 300),
          contentSize: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).visibleContentRect,
        Rect.fromLTWH(0, 0, 400, 200),
      );
    });

    test('visibleContentRect - when content is partially visible at the bottom',
        () {
      expect(
        _TestSheetMetrics(
          offset: 100,
          size: Size(400, 300),
          contentSize: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).visibleContentRect,
        Rect.fromLTWH(0, 700, 400, 100),
      );
    });

    test('visibleContentRect - when content is not visible', () {
      expect(
        _TestSheetMetrics(
          offset: 1200,
          size: Size(400, 300),
          contentSize: Size(400, 300),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
        ).visibleContentRect,
        null,
      );
    });

    test('staticOverlap - when sheet is not overlapped by static UI', () {
      expect(
        _TestSheetMetrics(
          offset: 800,
          size: Size(400, 800),
          contentSize: Size(400, 800),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
          viewportStaticOverlap: EdgeInsets.zero,
        ).staticOverlap,
        EdgeInsets.zero,
      );
    });

    test(
      'staticOverlap - when four edges of sheet are overlapped by static UI',
      () {
        expect(
          _TestSheetMetrics(
            offset: 800,
            size: Size(400, 800),
            contentSize: Size(400, 800),
            viewportSize: Size(400, 800),
            viewportPadding: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
          ).staticOverlap,
          EdgeInsets.fromLTRB(10, 20, 30, 40),
        );
      },
    );

    test('staticOverlap - when top of sheet is outside of viewport', () {
      expect(
        _TestSheetMetrics(
          offset: 1200,
          size: Size(400, 700),
          contentSize: Size(400, 700),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
          viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
        ).staticOverlap,
        EdgeInsets.fromLTRB(10, 20, 30, 0),
      );
    });

    test('staticOverlap - when bottom of sheet is outside of viewport', () {
      expect(
        _TestSheetMetrics(
          offset: 300,
          size: Size(400, 700),
          contentSize: Size(400, 700),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
          viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
        ).staticOverlap,
        EdgeInsets.fromLTRB(10, 0, 30, 40),
      );
    });

    test('dynamicOverlap - when sheet is not overlapped by dynamic UI', () {
      expect(
        _TestSheetMetrics(
          offset: 800,
          size: Size(400, 800),
          contentSize: Size(400, 800),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
          viewportDynamicOverlap: EdgeInsets.zero,
        ).dynamicOverlap,
        EdgeInsets.zero,
      );
    });

    test(
      'dynamicOverlap - when four edges of sheet are overlapped by dynamic UI',
      () {
        expect(
          _TestSheetMetrics(
            offset: 800,
            size: Size(400, 800),
            contentSize: Size(400, 800),
            viewportSize: Size(400, 800),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
          ).dynamicOverlap,
          EdgeInsets.fromLTRB(10, 20, 30, 40),
        );
      },
    );

    test('dynamicOverlap - when top of sheet is outside of viewport', () {
      expect(
        _TestSheetMetrics(
          offset: 1200,
          size: Size(400, 700),
          contentSize: Size(400, 700),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
          viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
        ).dynamicOverlap,
        EdgeInsets.fromLTRB(10, 20, 30, 0),
      );
    });

    test('dynamicOverlap - when bottom of sheet is outside of viewport', () {
      expect(
        _TestSheetMetrics(
          offset: 300,
          size: Size(400, 700),
          contentSize: Size(400, 700),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
          viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
        ).dynamicOverlap,
        EdgeInsets.fromLTRB(10, 0, 30, 40),
      );
    });

    test('contentStaticOverlap - when content is not overlapped by static UI',
        () {
      expect(
        _TestSheetMetrics(
          offset: 800,
          size: Size(400, 800),
          contentSize: Size(400, 800),
          viewportSize: Size(400, 800),
          viewportPadding: EdgeInsets.zero,
          viewportStaticOverlap: EdgeInsets.zero,
        ).contentStaticOverlap,
        EdgeInsets.zero,
      );
    });

    test(
      'contentStaticOverlap - when four edges of content are overlapped '
      'by static UI',
      () {
        expect(
          _TestSheetMetrics(
            offset: 800,
            size: Size(400, 800),
            contentSize: Size(400, 800),
            viewportSize: Size(400, 800),
            viewportPadding: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
          ).contentStaticOverlap,
          EdgeInsets.fromLTRB(10, 20, 30, 40),
        );
      },
    );

    test(
      'contentStaticOverlap - when top of content is outside of viewport',
      () {
        expect(
          _TestSheetMetrics(
            offset: 1200,
            size: Size(400, 700),
            contentSize: Size(400, 700),
            viewportSize: Size(400, 800),
            viewportPadding: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
          ).contentStaticOverlap,
          EdgeInsets.fromLTRB(10, 20, 30, 0),
        );
      },
    );

    test(
      'contentStaticOverlap - when bottom of content is outside of viewport',
      () {
        expect(
          _TestSheetMetrics(
            offset: 300,
            size: Size(400, 700),
            contentSize: Size(400, 700),
            viewportSize: Size(400, 800),
            viewportPadding: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
          ).contentStaticOverlap,
          EdgeInsets.fromLTRB(10, 0, 30, 40),
        );
      },
    );

    test(
      'contentDynamicOverlap - when content is not overlapped by dynamic UI',
      () {
        expect(
          _TestSheetMetrics(
            offset: 800,
            size: Size(400, 800),
            contentSize: Size(400, 800),
            viewportSize: Size(400, 800),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.zero,
          ).contentDynamicOverlap,
          EdgeInsets.zero,
        );
      },
    );

    test(
      'contentDynamicOverlap - when four edges of content are overlapped '
      'by dynamic UI',
      () {
        expect(
          _TestSheetMetrics(
            offset: 800,
            size: Size(400, 800),
            contentSize: Size(400, 800),
            viewportSize: Size(400, 800),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
          ).contentDynamicOverlap,
          EdgeInsets.fromLTRB(10, 20, 30, 40),
        );
      },
    );

    test(
      'contentDynamicOverlap - when top of content is outside of viewport',
      () {
        expect(
          _TestSheetMetrics(
            offset: 1200,
            size: Size(400, 700),
            contentSize: Size(400, 700),
            viewportSize: Size(400, 800),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
          ).contentDynamicOverlap,
          EdgeInsets.fromLTRB(10, 20, 30, 0),
        );
      },
    );

    test(
      'contentDynamicOverlap - when bottom of content is '
      'outside of viewport',
      () {
        expect(
          _TestSheetMetrics(
            offset: 300,
            size: Size(400, 700),
            contentSize: Size(400, 700),
            viewportSize: Size(400, 800),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
          ).contentDynamicOverlap,
          EdgeInsets.fromLTRB(10, 0, 30, 40),
        );
      },
    );
  });
}

/// A test implementation of [SheetMetrics] that throws an exception
/// when a field that is not specified in the constructor is used.
class _TestSheetMetrics with SheetMetrics {
  const _TestSheetMetrics({
    double? contentBaseline,
    Size? contentSize,
    double? devicePixelRatio,
    double? maxOffset,
    double? minOffset,
    double? offset,
    Size? size,
    EdgeInsets? viewportDynamicOverlap,
    EdgeInsets? viewportPadding,
    Size? viewportSize,
    EdgeInsets? viewportStaticOverlap,
  })  : _contentBaseline = contentBaseline,
        _contentSize = contentSize,
        _devicePixelRatio = devicePixelRatio,
        _maxOffset = maxOffset,
        _minOffset = minOffset,
        _offset = offset,
        _size = size,
        _viewportDynamicOverlap = viewportDynamicOverlap,
        _viewportPadding = viewportPadding,
        _viewportSize = viewportSize,
        _viewportStaticOverlap = viewportStaticOverlap;

  final double? _contentBaseline;
  final Size? _contentSize;
  final double? _devicePixelRatio;
  final double? _maxOffset;
  final double? _minOffset;
  final double? _offset;
  final Size? _size;
  final EdgeInsets? _viewportDynamicOverlap;
  final EdgeInsets? _viewportPadding;
  final Size? _viewportSize;
  final EdgeInsets? _viewportStaticOverlap;

  @override
  double get contentBaseline =>
      _contentBaseline ?? (throw UnimplementedError());

  @override
  Size get contentSize => _contentSize ?? (throw UnimplementedError());

  @override
  double get devicePixelRatio =>
      _devicePixelRatio ?? (throw UnimplementedError());

  @override
  double get maxOffset => _maxOffset ?? (throw UnimplementedError());

  @override
  double get minOffset => _minOffset ?? (throw UnimplementedError());

  @override
  double get offset => _offset ?? (throw UnimplementedError());

  @override
  Size get size => _size ?? (throw UnimplementedError());

  @override
  EdgeInsets get viewportDynamicOverlap =>
      _viewportDynamicOverlap ?? (throw UnimplementedError());

  @override
  EdgeInsets get viewportPadding =>
      _viewportPadding ?? (throw UnimplementedError());

  @override
  Size get viewportSize => _viewportSize ?? (throw UnimplementedError());

  @override
  EdgeInsets get viewportStaticOverlap =>
      _viewportStaticOverlap ?? (throw UnimplementedError());

  @override
  SheetMetrics copyWith({
    double? offset,
    double? minOffset,
    double? maxOffset,
    Size? size,
    Size? contentSize,
    Size? viewportSize,
    EdgeInsets? viewportPadding,
    EdgeInsets? viewportDynamicOverlap,
    EdgeInsets? viewportStaticOverlap,
    double? contentBaseline,
    double? devicePixelRatio,
  }) {
    throw UnimplementedError();
  }
}
