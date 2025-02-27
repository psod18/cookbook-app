import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


String get datestamp => DateFormat('ddMMyyyy').format(DateTime.now());

final validCharacters = RegExp(r'^[a-zA-Z0-9_\-]+$');

class FileNameDialog extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _FileNameDialogState();
}


class _FileNameDialogState extends State<FileNameDialog> {

  TextEditingController _fileName = TextEditingController(text: 'shoplist_$datestamp');
  
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[200],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Save Shoplist',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ),
               Container(
                margin: const EdgeInsets.only(top: 18, right: 18, bottom: 10),
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.orange),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Center(
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 15.0,
                    ),
                  ),
                ),
              ),
            ]
          ),
          Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _fileName,
                  decoration: const InputDecoration(
                    labelText: "Save as ...",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    if (!validCharacters.hasMatch(value)) {
                      return 'Invalid characters. Use only letters, numbers, - or _';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
          ),
          ElevatedButton(
            child: const Icon(Icons.save),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop(_fileName.text);
              }
            },
          ),
        ],
      ),
    );
  }
}
