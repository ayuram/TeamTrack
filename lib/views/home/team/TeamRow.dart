import 'package:flutter/material.dart';
import 'package:teamtrack/components/BarGraph.dart';
import 'package:teamtrack/components/PercentChange.dart';
import 'package:teamtrack/models/GameModel.dart';
import 'package:teamtrack/functions/Statistics.dart';
import 'package:teamtrack/models/ScoreModel.dart';
import 'package:teamtrack/models/StatConfig.dart';

class TeamRow extends StatelessWidget {
  const TeamRow({
    Key? key,
    required this.team,
    required this.event,
    required this.max,
    this.sortMode,
    this.onTap,
    required this.statConfig,
    required this.opr,
  }) : super(key: key);
  final Team team;
  final double opr;
  final Event event;
  final double max;
  final OpModeType? sortMode;
  final void Function()? onTap;
  final StatConfig statConfig;

  @override
  Widget build(context) {
    final percentIncrease = statConfig.allianceTotal
        ? event
            .getMatches(team)
            .map((e) => e.alliance(team)?.total())
            .whereType<Score>()
            .percentIncrease()
        : team.scores
            .map(
                (key, value) => MapEntry(key, value.getScoreDivision(sortMode)))
            .values
            .percentIncrease();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: ListTile(
        title: Text(
          team.name,
          style: Theme.of(context).textTheme.bodyText1,
        ),
        leading: Text(
          team.number,
          style: Theme.of(context).textTheme.caption,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (percentIncrease != null) PercentChange(percentIncrease),
            Padding(
              padding: EdgeInsets.all(
                10,
              ),
            ),
            RotatedBox(
              quarterTurns: 1,
              child: BarGraph(
                height: 70,
                width: 30,
                val: opr,
                max: max,
                title: 'OPR',
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
