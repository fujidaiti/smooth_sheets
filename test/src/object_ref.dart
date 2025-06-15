class ObjectRef<T> {
  const ObjectRef();

  static final _refs = Expando<Object>();

  T? get value => _refs[this] as T?;
  set value(T? value) => _refs[this] = value;
}
