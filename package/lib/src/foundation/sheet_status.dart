/// The status of a sheet.
enum SheetStatus {
  /// The sheet is resting at a natural position.
  stable,

  /// The sheet position is controlled by a programmatic way such as animation.
  controlled,

  /// The sheet position is controlled by a user gesture such as dragging.
  userControlled,
}
