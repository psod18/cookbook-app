import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({super.key, required this.item});
  final String item;

  @override
  Widget build(BuildContext context) {
   return AlertDialog(
      title: Text('Please Confirm'),
      content: Text("Are you sure you want to delete '$item'?"),
      actions: [
        TextButton(
          onPressed: () {
            // navigaet pop
            Navigator.of(context).pop(true);
          },
          child: const Text('Yes')),
        TextButton(
          onPressed: () {
            // Close the dialog
            Navigator.of(context).pop(false);
          },
          child: const Text('No')),
      ],  
    );
  }
}
