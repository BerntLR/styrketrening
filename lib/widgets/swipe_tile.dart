import 'package:flutter/material.dart';

/// Karo-standard for lister: sveip hoyre = rediger (bla), venstre = slett (rod).
/// Fargen folger de avrundede hjornene. Sletting ma bekreftes i [onDelete]
/// (returner true hvis elementet ble fjernet).
class SwipeTile extends StatelessWidget {
  const SwipeTile({
    super.key,
    required this.id,
    required this.child,
    this.onEdit,
    this.onDelete,
    this.radius = 12,
  });

  final String id;
  final Widget child;
  final VoidCallback? onEdit;
  final Future<bool> Function()? onDelete;
  final double radius;

  static const edit = Color(0xFF1E88E5);
  static const delete = Color(0xFFD32F2F);

  Widget _bg(Color c, IconData icon, Alignment a) => Container(
    decoration: BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(radius),
    ),
    alignment: a,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Icon(icon, color: Colors.white),
  );

  @override
  Widget build(BuildContext context) {
    final dir = onEdit != null && onDelete != null
        ? DismissDirection.horizontal
        : onEdit != null
        ? DismissDirection.startToEnd
        : onDelete != null
        ? DismissDirection.endToStart
        : DismissDirection.none;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(id),
        direction: dir,
        background: _bg(edit, Icons.edit, Alignment.centerLeft),
        secondaryBackground: _bg(delete, Icons.delete, Alignment.centerRight),
        confirmDismiss: (d) async {
          if (d == DismissDirection.startToEnd) {
            onEdit?.call();
            return false;
          }
          return await onDelete?.call() ?? false;
        },
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}

/// Felles bekreftelsesdialog for sletting.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required String cancel,
  required String confirm,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text(cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirm, style: const TextStyle(color: SwipeTile.delete)),
        ),
      ],
    ),
  );
  return ok == true;
}
