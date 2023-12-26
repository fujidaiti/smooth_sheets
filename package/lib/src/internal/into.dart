extension Into<T> on T {
  U? intoOrNull<U>() => this is U ? this as U : null;
}
