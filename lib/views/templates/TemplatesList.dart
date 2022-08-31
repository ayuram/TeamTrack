import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:teamtrack/components/misc/PlatformGraphics.dart';
import 'package:teamtrack/models/GameModel.dart';
import '../../api/APIKEYS.dart';
import '../../functions/APIMethods.dart';

import 'TemplateView.dart';

class TemplatesList extends StatefulWidget {
  TemplatesList({Key? key, this.onTap}) : super(key: key);
  final void Function(Event)? onTap;
  @override
  _TemplatesList createState() => _TemplatesList();
}

class _TemplatesList extends State<TemplatesList> {
  final seasonKey = '2021';
  final url = 'https://theorangealliance.org/api';
  bool loaded = false;
  // ···
  List bod = [];
  List bodvis = [];
  _getEvents() {
    APIMethods.getEvents().then((response) {
      setState(() {
        bod = (json.decode(response.body).toList());
        bodvis = bod;
      });
    });
  }

  initState() {
    super.initState();
    _getEvents();
  }

  onSearch(String search) {
    setState(() {
      bodvis = bod
          .where((element) =>
              element['event_name']
                      .toString()
                      .toLowerCase()
                      .indexOf(search.toLowerCase()) !=
                  -1 &&
              element['venue'].toString() != 'Virtual' &&
              element['venue'].toString() != 'Remote' &&
              element['event_name']
                      .toString()
                      .toLowerCase()
                      .indexOf('remote'.toLowerCase()) ==
                  -1)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey.shade900,
        title: Container(
          height: 38,
          child: TextField(
            onChanged: (value) => onSearch(value),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[850],
              contentPadding: EdgeInsets.all(0),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade500,
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none),
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              hintText: "Search events",
            ),
          ),
        ),
      ),
      body: Container(
        child: bod.isEmpty
            ? Center(child: PlatformProgressIndicator())
            : bodvis.isEmpty
                ? Center(child: Text('No Results Found'))
                : ListView.builder(
                    itemCount: bodvis.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                            title: Text(bodvis[index]['event_name']),
                            onTap: () {
                              Navigator.push(
                                context,
                                platformPageRoute(
                                  builder: (_) => TemplateView(
                                    eventKey: bodvis[index]['event_key'],
                                    eventName: bodvis[index]['event_name'],
                                  ),
                                ),
                              );
                            }),
                      );
                    },
                  ),
      ),
    );
  }
}
