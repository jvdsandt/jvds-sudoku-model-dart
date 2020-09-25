import 'dart:collection';
import 'dart:math';

import '../jvds_sudoku_model.dart';

abstract class SudokuGameBase {
  final SudokuOptionsPerCell optionsPerCell;

  const SudokuGameBase(this.optionsPerCell);

  SudokuGame get game;

  SudokuBoard get board => game.board;

  int valueAt(SudokuCell cell);

  Map<SudokuCell, int> get solvedCells => {};

  bool isSolved() => false;

  SudokuMove lastMove();

  SudokuGameBase doNextMove() {
    SudokuMove move = optionsPerCell.firstSingleOption();
    if (move != null) {
      return _newMove(move, false);
    }
    for (var box in board.boxes) {
      move = box.findMove(optionsPerCell);
      if (move != null) {
        return _newMove(move, false);
      }
    }
    return _newMove(optionsPerCell.takeGuess(), true);
  }

  SudokuGameBase solve() {
    var game = this;
    while (!game.isSolved()) {
      game = game.doNextMove();
    }
    return game;
  }

  @override
  String toString() {
    var buf = new StringBuffer();
    for (int y = 1; y <= board.maxY; y++) {
      for (int x = 1; x <= board.maxX; x++) {
        var val = valueAt(new SudokuCell(x, y));
        buf.write(val == null ? "? " : "$val ");
      }
      buf.writeln();
    }
    return buf.toString();
  }

  SudokuGameBase _newMove(SudokuMove nextMove, bool guessed) {
    var newOptions = optionsPerCell.copyWithMove(board, nextMove);
    if (newOptions == null) {
      throw new Exception("invalid options");
    }
    Map<SudokuCell, int> newSolvedCells = new Map.from(solvedCells)
      ..[nextMove.cell] = nextMove.value;

    return new SudokuAutoGame(
        this, nextMove, newOptions, newSolvedCells, guessed);
  }
}


class SudokuGamePlay extends SudokuGameBase {
  final SudokuGame game;
  final SudokuGameBase previousPlay;
  final Map<SudokuCell, int> solvedCells;
  final SudokuMove _lastMove;

  SudokuGamePlay(SudokuGameBase previousPlay, SudokuMove lastMove,
      SudokuOptionsPerCell options, Map<SudokuCell, int> solvedCells)
      : this.game = previousPlay.game,
      this.previousPlay = previousPlay,
      this.solvedCells = solvedCells,
      this._lastMove = lastMove,
      super(options);

  @override
  SudokuMove lastMove() {
    return _lastMove;
  }

  @override
  int valueAt(SudokuCell cell) {
    int value = solvedCells[cell];
    if (value == null) {
      value = game.valueAt(cell);
    }
    return value;
  }

  bool isSolved() => game.numberOfCellsToSolve == solvedCells.length;
}

class SudokuAutoGame extends SudokuGamePlay {
  final bool guessed;

  SudokuAutoGame(
      SudokuGameBase previousPlay,
      SudokuMove lastMove,
      SudokuOptionsPerCell options,
      Map<SudokuCell, int> solvedCells,
      bool guessed)
      : this.guessed = guessed,
        super(previousPlay, lastMove, options, solvedCells);
}



class SudokuOptionsPerCell {
  final Map<SudokuCell, List<int>> map;

  const SudokuOptionsPerCell(this.map);

  static create(SudokuBoard board, Map<SudokuCell, int> fixedCells) {
    var options = HashMap<SudokuCell, List<int>>();
    for (var cell in board.relevantCells()) {
      if (!fixedCells.containsKey(cell)) {
        options[cell] = board.possibleValues(cell, fixedCells);
      }
    }
    return new SudokuOptionsPerCell(options);
  }

  List<int> operator [](SudokuCell cell) => map[cell];

  bool containsCell(SudokuCell cell) => map.containsKey(cell);

  SudokuMove firstSingleOption() {
    var cell = map.keys
        .firstWhere((cell) => map[cell].length == 1, orElse: () => null);
    return cell == null
        ? null
        : new SudokuMove(cell, map[cell].first, MoveReason.ONLY_OPTION);
  }

  SudokuMove takeGuess() {
    List minValues;
    var cell;
    map.forEach((eachCell, eachValues) {
      if (minValues == null || minValues.length > eachValues.length) {
        cell = eachCell;
        minValues = eachValues;
      }
    });
    return new SudokuMove(cell, minValues.first, MoveReason.GUESS);
  }

  SudokuOptionsPerCell copyWithMove(SudokuBoard board, SudokuMove move) {
    Map<SudokuCell, List<int>> newMap = new Map.from(map);
    newMap.remove(move.cell);

    board.cellsSharingBoxWith(move.cell, (eachCell) {
      var values = newMap[eachCell];
      if (values != null) {
        values = new List.from(values)..remove(move.value);
        if (values.isEmpty) {
          return null;
        }
        newMap[eachCell] = values;
      }
    });
    return new SudokuOptionsPerCell(newMap);
  }
}

