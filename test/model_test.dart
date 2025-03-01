import 'package:flutter/widgets.dart';
import 'package:smooth_sheets/src/model.dart';

import 'src/flutter_test_x.dart';

void main() {
  group('SheetLayoutSpec', () {
    test(
      'maxSheetRect should match the viewport if there is no padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetRect,
          Rect.fromLTWH(0, 0, 800, 600),
        );
      },
    );

    test(
      'maxSheetRect should be reduced by the viewport padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.fromLTRB(10, 20, 30, 40),
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetRect,
          Rect.fromLTRB(10, 20, 770, 560),
        );
      },
    );

    test(
      'maxContentRect should always match the maxSheetRect '
      'when resizeContentToAvoidBottomInset is false, '
      'regardless of the bottom view-inset',
      () {
        var spec = SheetLayoutSpec(
          viewportSize: Size(800, 600),
          viewportPadding: EdgeInsets.zero,
          viewportDynamicOverlap: EdgeInsets.zero,
          viewportStaticOverlap: EdgeInsets.zero,
          resizeContentToAvoidBottomOverlap: false,
        );
        expect(spec.maxContentRect, equals(spec.maxSheetRect));

        spec = SheetLayoutSpec(
          viewportSize: Size(800, 600),
          viewportPadding: EdgeInsets.zero,
          viewportStaticOverlap: EdgeInsets.zero,
          // Apply non-zero bottom inset.
          viewportDynamicOverlap: EdgeInsets.only(bottom: 50),
          resizeContentToAvoidBottomOverlap: false,
        );
        expect(spec.maxContentRect, equals(spec.maxSheetRect));
      },
    );

    test(
      'maxContentRect should reduce the height to avoid the bottom view inset '
      'if resizeContentToAvoidBottomInset is true',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.only(bottom: 50),
            resizeContentToAvoidBottomOverlap: true,
          ).maxContentRect,
          Rect.fromLTRB(0, 0, 800, 550),
        );
      },
    );

    test(
      'maxSheetStaticOverlap: when static overlap is greater than padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetStaticOverlap,
          EdgeInsets.fromLTRB(10, 20, 30, 40),
        );
      },
    );

    test(
      'maxSheetStaticOverlap: when static overlap is less than padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.all(40),
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetStaticOverlap,
          EdgeInsets.zero,
        );
      },
    );

    test(
      'maxSheetDynamicOverlap: when dynamic overlap is greater than padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetDynamicOverlap,
          EdgeInsets.fromLTRB(10, 20, 30, 40),
        );
      },
    );

    test(
      'maxSheetDynamicOverlap: when dynamic overlap is less than padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.all(40),
            viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: false,
          ).maxSheetDynamicOverlap,
          EdgeInsets.zero,
        );
      },
    );

    test(
      'maxContentDynamicOverlap: when dynamic overlap is greater than padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.all(10),
            viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: false,
          ).maxContentDynamicOverlap,
          EdgeInsets.fromLTRB(0, 10, 20, 30),
        );
      },
    );

    test(
      'maxContentDynamicOverlap: when dynamic overlap is greater than padding '
      'and the content is shrunk to avoid the bottom inset',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.zero,
            viewportDynamicOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            viewportStaticOverlap: EdgeInsets.zero,
            resizeContentToAvoidBottomOverlap: true,
          ).maxContentDynamicOverlap,
          EdgeInsets.fromLTRB(10, 20, 30, 0),
        );
      },
    );

    test(
      'maxContentStaticOverlap: when static overlap is greater than padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.all(10),
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            resizeContentToAvoidBottomOverlap: false,
          ).maxContentStaticOverlap,
          EdgeInsets.fromLTRB(0, 10, 20, 30),
        );
      },
    );

    test(
      'maxContentStaticOverlap: when static overlap is less than padding',
      () {
        expect(
          SheetLayoutSpec(
            viewportSize: Size(800, 600),
            viewportPadding: EdgeInsets.all(40),
            viewportDynamicOverlap: EdgeInsets.zero,
            viewportStaticOverlap: EdgeInsets.fromLTRB(10, 20, 30, 40),
            resizeContentToAvoidBottomOverlap: false,
          ).maxContentStaticOverlap,
          EdgeInsets.zero,
        );
      },
    );
  });
}
