// TODO: Consider removing this API.
/// The status of a sheet.
enum SheetStatus {
  /// The sheet is resting at a natural position.
  stable,

  /// The sheet is animating to a new position.
  animating,

  /// The sheet position is controlled by the user dragging it.
  dragging,
}
