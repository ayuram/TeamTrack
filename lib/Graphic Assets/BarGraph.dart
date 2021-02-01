import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BarGraph extends StatelessWidget {
  BarGraph(
      {Key key,
      this.max,
      this.val,
      this.inverted = false,
      this.height = 150,
      this.title = 'Default'})
      : super(key: key);
  final String title;
  final double max;
  final double val;
  final bool inverted;
  final double height;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: Theme.of(context).textTheme.caption),
        Padding(
          padding: EdgeInsets.all(2),
        ),
        Stack(
          alignment: AlignmentDirectional.bottomStart,
          children: [
            Container(
              width: 40,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: Theme.of(context).canvasColor.inverseColor(1),
              ),
            ),
            AnimatedContainer(
              curve: Curves.fastLinearToSlowEaseIn,
              duration: Duration(milliseconds: 600),
              width: 40,
              height: inverted
                  ? (val != 0 ? max / val : 0) * height
                  : (max != 0 ? val / max : 0) * height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: _colorSelect(val, max),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.all(2),
        ),
        Text(val.toInt().toString(),
            style: Theme.of(context).textTheme.caption),
      ],
    );
  }

  Color _colorSelect(double val, double max) {
    if (val / max < 0.5) {
      return CupertinoColors.systemRed;
    } else if (val / max < 0.7) {
      return CupertinoColors.systemYellow;
    } else {
      return CupertinoColors.systemGreen;
    }
  }
}

extension colorExtensions on Color {
  Color inverseColor(double opacity) {
    return Color.fromRGBO(
        255 - this.red, 255 - this.green, 255 - this.blue, opacity);
  }
}
