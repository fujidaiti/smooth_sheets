import 'package:cookbook/showcase/todo_list/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

Future<Todo?> showTodoEditor(BuildContext context) {
  return Navigator.push(
    context,
    ModalSheetRoute(
      swipeDismissible: true,
      viewportPadding: EdgeInsets.only(
        // Add a top padding to avoid the status bar.
        top: MediaQuery.viewPaddingOf(context).top,
      ),
      builder: (context) => TodoEditor(),
    ),
  );
}

class TodoEditor extends StatefulWidget {
  const TodoEditor({super.key});

  @override
  State<TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends State<TodoEditor> {
  late final _EditingController controller;

  @override
  void initState() {
    super.initState();
    controller = _EditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> onPopInvoked(bool didPop, Object? result) async {
    if (didPop) {
      // Already popped.
      return;
    } else if (!controller.canCompose.value) {
      // Dismiss immediately if there are no unsaved changes.
      Navigator.pop(context);
      return;
    }

    // Show a confirmation dialog.
    final shouldPop = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (shouldPop == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleInput = _MultiLineInput(
      hintText: 'Title',
      autofocus: true,
      style: Theme.of(context).textTheme.titleLarge,
      textInputAction: TextInputAction.next,
      onChanged: (value) => controller.title.value = value,
    );

    final descriptionInput = _MultiLineInput(
      hintText: 'Description',
      style: Theme.of(context).textTheme.bodyLarge,
      textInputAction: TextInputAction.newline,
      onChanged: (value) => controller.description.value = value,
    );

    final attributes = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DateTimePicker(controller),
        const SizedBox(width: 8),
        _PrioritySelector(controller),
        const SizedBox(width: 8),
        _Reminder(controller),
      ],
    );

    final body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: titleInput,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: descriptionInput,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: attributes,
          ),
        ],
      ),
    );

    final bottomBar = Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        child: SizedBox.fromSize(
          size: const Size.fromHeight(kToolbarHeight),
          child: Row(
            children: [
              _FolderSelector(controller),
              const Spacer(),
              _SubmitButton(controller),
            ],
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: onPopInvoked,
      child: SheetKeyboardDismissible(
        dismissBehavior: const SheetKeyboardDismissBehavior.onDragDown(
          isContentScrollAware: true,
        ),
        child: Sheet(
          scrollConfiguration: const SheetScrollConfiguration(),
          decoration: MaterialSheetDecoration(
            size: SheetSize.stretch,
            color: Theme.of(context).colorScheme.secondaryContainer,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          child: SheetContentScaffold(
            bottomBarVisibility: const BottomBarVisibility.always(
              // Make the bottom bar visible when the keyboard is open.
              ignoreBottomInset: true,
            ),
            body: body,
            bottomBar: bottomBar,
          ),
        ),
      ),
    );
  }
}

class _MultiLineInput extends StatelessWidget {
  const _MultiLineInput({
    required this.hintText,
    this.onChanged,
    this.style,
    this.textInputAction,
    this.autofocus = false,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: autofocus,
      maxLines: null,
      textInputAction: textInputAction,
      onChanged: onChanged,
      style: style,
      decoration: InputDecoration(
        hintText: hintText,
        border: InputBorder.none,
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton(this.controller);

  final _EditingController controller;

  void onPressed(BuildContext context) {
    final todo = controller.compose();
    Navigator.pop(context, todo);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.canCompose,
      builder: (context, canCompose, _) {
        return IconButton.filled(
          onPressed: canCompose ? () => onPressed(context) : null,
          icon: const Icon(Icons.arrow_upward),
          tooltip: 'Submit',
        );
      },
    );
  }
}

const _prioritySelectorPopupMenuHeight = 160.0;

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector(this.controller);

  final _EditingController controller;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, -_prioritySelectorPopupMenuHeight),
      style: MenuStyle(
        alignment: Alignment.bottomLeft,
        maximumSize: WidgetStateProperty.all(
          const Size.fromHeight(_prioritySelectorPopupMenuHeight),
        ),
      ),
      menuChildren: [
        for (final priority in Priority.values)
          MenuItemButton(
            leadingIcon: buildFlagIcon(priority),
            child: Text(priority.displayName),
            onPressed: () => controller.priority.value = priority,
          ),
      ],
      builder: (context, menuController, _) {
        return ValueListenableBuilder(
          valueListenable: controller.priority,
          builder: (context, priority, _) {
            return ActionChip(
              avatar: buildFlagIcon(priority),
              label: Text(priority.displayName),
              onPressed: () {
                if (menuController.isOpen) {
                  menuController.close();
                } else {
                  menuController.open();
                }
              },
            );
          },
        );
      },
    );
  }

  Widget buildFlagIcon(Priority priority) {
    return switch (priority.color) {
      null => const Icon(Icons.flag_outlined),
      final color => Icon(Icons.flag, color: color),
    };
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker(this.controller);

  final _EditingController controller;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.event),
      label: const Text('No date'),
      onPressed: () {},
    );
  }
}

class _Reminder extends StatelessWidget {
  const _Reminder(this.controller);

  final _EditingController controller;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.alarm),
      label: const Text('Reminder'),
      onPressed: () {},
    );
  }
}

class _FolderSelector extends StatelessWidget {
  const _FolderSelector(this.controller);

  final _EditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.folder_outlined),
      label: const Row(
        children: [
          Text('Inbox'),
          SizedBox(width: 16),
          Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

class _EditingController extends ChangeNotifier {
  _EditingController() {
    title.addListener(() {
      _canCompose.value = title.value?.isNotEmpty == true;
    });
  }

  final title = ValueNotifier<String?>(null);
  final description = ValueNotifier<String?>(null);
  final priority = ValueNotifier(Priority.none);

  final _canCompose = ValueNotifier(false);
  ValueListenable<bool> get canCompose => _canCompose;

  Todo compose() {
    assert(title.value != null);
    return Todo(
      title: title.value!.trim(),
      description: description.value?.trim(),
      priority: priority.value,
    );
  }
}
