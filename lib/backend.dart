import 'dart:math';
import 'score.dart';
import 'package:uuid/uuid.dart';
import 'package:fl_chart/fl_chart.dart';

class DataModel {
  List<Event> localEvents() {
    return events.where((e) => e.type == EventType.local).toList();
  }

  List<Event> remoteEvents() {
    return events.where((e) => e.type == EventType.remote).toList();
  }

  List<Event> liveEvents() {
    return events.where((e) => e.type == EventType.live).toList();
  }

  List<Event> events = [];
}

class Event {
  Event({this.name, this.type});
  EventType type;
  List<Team> teams = [];
  List<Match> matches = [];
  String name;
  void addTeam(Team newTeam) {
    bool isIn = false;
    teams.forEach((element) {
      if (element.equals(newTeam)) isIn = true;
    });
    if (!isIn) teams.add(newTeam);
    teams.sortTeams();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'teams': teams,
        'matches': matches,
        'type': type,
      };
}

class Alliance {
  Team item1;
  Team item2;
  Alliance(Team item1, Team item2) {
    this.item1 = item1;
    this.item2 = item2;
  }
  int allianceTotal(Uuid id) {
    return item1.scores.firstWhere((e) => e.id == id).total() +
        item2.scores.firstWhere((e) => e.id == id).total();
  }

  Map<String, dynamic> toJson() => {
        'item1': item1,
        'item2': item2,
      };
}

class Team {
  String name;
  String number;
  List<Score> scores;
  Team(String number, String name) {
    this.name = name;
    this.number = number;
    scores = List();
  }
  static Team nullTeam() {
    return Team("1", "1");
  }

  bool equals(Team other) {
    return this.number == other.number;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
        'scores': scores,
      };
}

class Match {
  EventType type = EventType.live;
  Dice dice = Dice.one;
  Alliance red;
  Alliance blue;
  Uuid id;
  Match(Alliance red, Alliance blue, EventType type) {
    this.type = type;
    this.red = red;
    this.blue = blue;
    id = Uuid();
    red.item1.scores.addScore(Score(id, dice));
    red.item2.scores.addScore(Score(id, dice));
    blue.item1.scores.addScore(Score(id, dice));
    blue.item2.scores.addScore(Score(id, dice));
  }
  static Match defaultMatch(EventType type) {
    return Match(Alliance(Team('1', 'Alpha'), Team('2', 'Beta')),
        Alliance(Team('3', 'Charlie'), Team('4', 'Delta')), type);
  }

  Alliance alliance(Team team) {
    if (red.item1.equals(team) || red.item2.equals(team)) {
      return red;
    } else if (blue.item1.equals(team) || blue.item2.equals(team)) {
      return blue;
    } else {
      return null;
    }
  }

  void setDice(Dice dice) {
    this.dice = dice;
    red.item1.scores.firstWhere((e) => e.id == id).dice = dice;
    red.item2.scores.firstWhere((e) => e.id == id).dice = dice;
    blue.item1.scores.firstWhere((e) => e.id == id).dice = dice;
    blue.item2.scores.firstWhere((e) => e.id == id).dice = dice;
  }

  String score() {
    if (type == EventType.remote) {
      return red.item1.scores.firstWhere((e) => e.id == id).total().toString();
    }
    return redScore() + " - " + blueScore();
  }

  String redScore() {
    final r0 = red.item1.scores.firstWhere((e) => e.id == id).total();
    final r1 = red.item2.scores.firstWhere((e) => e.id == id).total();
    return (r0 + r1).toString();
  }

  String blueScore() {
    final b0 = blue.item1.scores.firstWhere((e) => e.id == id).total();
    final b1 = blue.item2.scores.firstWhere((e) => e.id == id).total();
    return (b0 + b1).toString();
  }

  Map<String, dynamic> toJson() => {
        'red1': red.item1,
        'red2': red.item2,
        'blue1': blue.item1,
        'blue2': blue.item2,
      };
}

enum EventType { live, local, remote }
enum Dice { one, two, three, none }

extension DiceExtension on Dice {
  int stackHeight() {
    switch (this) {
      case Dice.one:
        return 0;
      case Dice.two:
        return 1;
      default:
        return 4;
    }
  }
}

extension IterableExtensions on Iterable<int> {
  List<FlSpot> spots() {
    List<FlSpot> val = [];
    for (int i = 0; i < this.length; i++) {
      val.add(FlSpot(i.toDouble(), this.toList()[i].toDouble()));
    }
    return val;
  }

  double mean() {
    if (this.length == 0) {
      return 0;
    } else {
      return this.reduce((value, element) => value += element) / this.length;
    }
  }

  double mad() {
    if (this.length == 0) {
      return 0;
    }
    final mean = this.mean();
    return this.map((e) => (e - mean).abs().toInt()).mean();
  }
}

extension MatchExtensions on List<Match> {
  List<FlSpot> spots(Team team) {
    List<FlSpot> val = [];
    for (int i = 0; i < this.length; i++) {
      final alliance = this[i].alliance(team);
      if (alliance != null) {
        final allianceTotal = alliance.allianceTotal(this[i].id);
        val.add(FlSpot(i.toDouble(), allianceTotal.toDouble()));
      }
    }
    return val;
  }

  int maxAllianceScore(Team team) {
    List<int> val = [];
    for (int i = 0; i < this.length; i++) {
      final alliance = this[i].alliance(team);
      if (alliance != null) {
        final allianceTotal = alliance.allianceTotal(this[i].id);
        val.add(allianceTotal);
      }
    }
    return val.reduce(max);
  }
}

extension TeamsExtension on List<Team> {
  Team findAdd(String number, String name) {
    bool found = false;
    for (Team team in this) {
      if (team.number ==
          number.replaceAll(new RegExp(r' [^\w\s]+'), '').replaceAll(' ', '')) {
        found = true;
      }
    }
    if (found) {
      var team = this.firstWhere((e) =>
          e.number ==
          number.replaceAll(new RegExp(r' [^\w\s]+'), '').replaceAll(' ', ''));
      team.name = name;
      return team;
    } else {
      var newTeam = Team(
          number.replaceAll(new RegExp(r' [^\w\s]+'), '').replaceAll(' ', ''),
          name);
      this.add(newTeam);
      this.sortTeams();
      return newTeam;
    }
  }

  void sortTeams() {
    this.sort((a, b) => int.parse(a.number).compareTo(int.parse(b.number)));
  }

  double maxScore() {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.maxScore()).reduce(max);
  }

  double lowestMadScore() {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.madScore()).reduce(min);
  }

  double maxAutoScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.autoMaxScore(dice)).reduce(max);
  }

  double lowestAutoMadScore(Dice dice) {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.autoMADScore(dice)).reduce(min);
  }

  double maxTeleScore() {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.teleMaxScore()).reduce(max);
  }

  double lowestTeleMadScore() {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.teleMADScore()).reduce(min);
  }

  double maxEndScore() {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.endMaxScore()).reduce(max);
  }

  double lowestEndMadScore() {
    if (this.length == 0) return 1;
    return this.map((e) => e.scores.endMADScore()).reduce(min);
  }
}

extension ScoresExtension on List<Score> {
  List<FlSpot> spots() {
    final list = this.map((e) => e.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  List<FlSpot> teleSpots() {
    final list = this.map((e) => e.teleScore.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  List<FlSpot> autoSpots() {
    final list = this.map((e) => e.autoScore.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  List<FlSpot> endSpots() {
    final list = this.map((e) => e.endgameScore.total()).toList();
    List<FlSpot> val = [];
    for (int i = 0; i < list.length; i++) {
      val.add(FlSpot(i.toDouble(), list[i].toDouble()));
    }
    return val;
  }

  double maxScore() {
    if (this.length == 0) return 0;
    return this.map((e) => e.total()).reduce(max).toDouble();
  }

  double minScore() {
    return this.map((e) => e.total()).reduce(min).toDouble();
  }

  double meanScore() {
    if (this.length == 0) return 0;
    return this.map((e) => e.total()).mean();
  }

  double madScore() {
    if (this.length == 0) return 0;
    return this.map((e) => e.total()).mad();
  }

  double teleMaxScore() {
    if (this.length == 0) return 0;
    return this.map((e) => e.teleScore.total()).reduce(max).toDouble();
  }

  double teleMinScore() {
    if (this.length == 0) return 0;
    return this.map((e) => e.teleScore.total()).reduce(min).toDouble();
  }

  double teleMeanScore() {
    if (this.length == 0) return 0;
    return this.map((e) => e.teleScore.total()).mean();
  }

  double teleMADScore() {
    if (this.length == 0) return 0;
    return this.map((e) => e.teleScore.total()).mad();
  }

  double autoMaxScore(Dice dice) {
    final arr = dice != Dice.none ? this.where((e) => e.dice == dice) : this;
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).reduce(max).toDouble();
  }

  double autoMinScore(Dice dice) {
    final arr = dice != Dice.none ? this.where((e) => e.dice == dice) : this;
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).reduce(min).toDouble();
  }

  double autoMeanScore(Dice dice) {
    final arr = dice != Dice.none ? this.where((e) => e.dice == dice) : this;
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).mean();
  }

  double autoMADScore(Dice dice) {
    final arr = dice != Dice.none ? this.where((e) => e.dice == dice) : this;
    if (arr.length == 0)
      return 0;
    else
      return arr.map((e) => e.autoScore.total()).mad();
  }

  double endMaxScore() {
    if (this.length == 0) return 0;
    return this.map((e) => e.endgameScore.total()).reduce(max).toDouble();
  }

  double endMinScore() {
    if (this.length == 0) return 0;
    return this.map((e) => e.endgameScore.total()).reduce(min).toDouble();
  }

  double endMeanScore() {
    if (this.length == 0) return 0;
    return this.map((e) => e.endgameScore.total()).mean();
  }

  double endMADScore() {
    if (this.length == 0) return 0;
    return this.map((e) => e.endgameScore.total()).mad();
  }
}

bool toggle(bool init) {
  if (init)
    return false;
  else
    return true;
}
