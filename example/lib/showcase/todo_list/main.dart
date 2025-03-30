import 'package:cookbook/showcase/todo_list/models.dart';
import 'package:cookbook/showcase/todo_list/todo_editor.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const _TodoListExample());
}

class _TodoListExample extends StatelessWidget {
  const _TodoListExample();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  late final TodoList _todoList;

  @override
  void initState() {
    super.initState();
    _todoList = TodoList();
  }

  @override
  void dispose() {
    _todoList.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
      ),
      body: _TodoListView(todoList: _todoList),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addTodo(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> addTodo() async {
    final todo = await showTodoEditor(context);
    if (todo != null) {
      _todoList.add(todo);
    }
  }
}

class _TodoListView extends StatelessWidget {
  const _TodoListView({
    required this.todoList,
  });

  final TodoList todoList;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: todoList,
      builder: (context, _) {
        return ListView.separated(
          itemCount: todoList.length,
          itemBuilder: (context, index) {
            return _TodoListViewItem(
              todo: todoList[index],
              checkboxCallback: (value) => todoList.toggle(index),
            );
          },
          separatorBuilder: (context, index) {
            return const Divider(indent: 24);
          },
        );
      },
    );
  }
}

class _TodoListViewItem extends StatelessWidget {
  const _TodoListViewItem({
    required this.todo,
    required this.checkboxCallback,
  });

  final Todo todo;
  final ValueChanged<bool?> checkboxCallback;

  @override
  Widget build(BuildContext context) {
    final statuses = <Widget>[
      if (todo.priority != Priority.none)
        _StatusChip(
          icon: Icons.flag,
          color: todo.priority.color,
          label: todo.priority.displayName,
        ),
    ];

    final description = switch (todo.description) {
      null => null,
      final text => Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.black54),
        ),
    };

    final secondaryContent = [
      if (description != null) ...[description, const SizedBox(height: 8)],
      if (statuses.isNotEmpty && !todo.isDone) Wrap(children: statuses),
    ];

    return CheckboxListTile(
      value: todo.isDone,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: checkboxCallback,
      title: Text(todo.title),
      isThreeLine: secondaryContent.isNotEmpty,
      subtitle: switch (secondaryContent.isNotEmpty) {
        true => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: secondaryContent,
          ),
        false => null,
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color? color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: color),
      label: Text(label),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.only(right: 12),
      visualDensity: const VisualDensity(
        vertical: -4,
        horizontal: -4,
      ),
    );
  }
}
