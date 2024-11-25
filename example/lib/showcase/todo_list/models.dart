import 'package:flutter/material.dart';

// TODO: Add 'reminder' and 'due date' fields.
class Todo {
  final String title;
  final String? description;
  final Priority priority;
  final bool isDone;

  const Todo({
    required this.title,
    this.description,
    this.priority = Priority.none,
    this.isDone = false,
  });
}

enum Priority {
  high(displayName: 'High Priority', color: Colors.red),
  medium(displayName: 'Medium Priority', color: Colors.orange),
  low(displayName: 'Low Priority', color: Colors.blue),
  none(displayName: 'No Priority');

  const Priority({
    required this.displayName,
    this.color,
  });

  final String displayName;
  final Color? color;
}

class TodoList extends ChangeNotifier {
  final List<Todo> _todos = [];

  int get length => _todos.length;

  Todo operator [](int index) => _todos[index];

  void add(Todo todo) {
    _todos.insert(0, todo);
    notifyListeners();
  }

  void toggle(int index) {
    final todo = _todos[index];
    _todos[index] = Todo(
      title: todo.title,
      description: todo.description,
      priority: todo.priority,
      isDone: !todo.isDone,
    );
    notifyListeners();
  }
}
