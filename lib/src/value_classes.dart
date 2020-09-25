import 'dart:math';

import 'value_builders.dart';

/**
 * Value class that represents a position on the board.
 */
class Cell implements Comparable {

  final int xpos;
  final int ypos;

  const Cell(this.xpos, this.ypos);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.xpos == xpos && other.ypos == ypos;

  @override
  int get hashCode => (xpos * 10) + ypos;

  @override
  String toString() => "${xpos}@${ypos}";

  @override
  int compareTo(o) => ypos == o.ypos ? xpos - o.xpos : ypos - o.ypos;
}

enum MoveReason {
  ONLY_OPTION,
  ONLY_PLACE,
  GUESS,
  MANUAL
}

/**
 * Value class that represents assigning a value to a cell.
 */
class Move implements Comparable {

  final Cell cell;
  final int value;
  final MoveReason reason;

  const Move(this.cell, this.value, this.reason);

  @override
  String toString() {
    return "${cell} -> ${value} (${reason})";
  }

  @override
  int compareTo(other) => cell.compareTo(other.cell);
}

abstract class CellAccess {

  const CellAccess();

  int valueAt(Cell c);

  void valueIfKnown(Cell aCell, Function(int) action) {
    int val = valueAt(aCell);
    if (val != -1) {
      action(val);
    }
  }
}

class SudokuBoard {

  final List<SudokuBox> boxes;
  int maxX;
  int maxY;

  static SudokuBoard default9x9() {
    return SudokuBoardBuilder.default9x9();
  }

  SudokuBoard(this.boxes) {
    this.maxX = boxes.map((e) => e.maxX()).reduce((value, e) => max(value, e));
    this.maxY = boxes.map((e) => e.maxY()).reduce((value, e) => max(value, e));
  }

  Set<Cell> relevantCells() =>
      boxes.fold(new Set(), (Set coll, box) {
        coll.addAll(box.cells);
        return coll;
      });

  void boxesFor(Cell cell, func(SudokuBox b)) {
    for (var box in boxes) {
      if (box.includes(cell)) {
        func(box);
      }
    }
  }

  void forRelevantCells(func(Cell)) {
    var cellSet = <Cell>{};
    boxes.forEach((eachBox) {
      eachBox.cells.forEach((eachCell) {
        if (!cellSet.contains(eachCell)) {
          func(eachCell);
          cellSet.add(eachCell);
        }
      });
    });
  }

  Set<int> possibleValues(Cell cell, CellAccess game) {
    const values = { 1, 2, 3, 4, 5, 6, 7, 8, 9};
    boxesFor(cell, (eachBox) {
      values = eachBox.possibleValues(cell, values, game);
    });
    return values;
  }

  Map<Cell, Set<int>> processMove(Map<Cell, Set<int>> optionsPerCell, Move move) {
    // todo
    return null;
  }
}

class SudokuBox {

  final String name;
  final List<Cell> cells;

  const SudokuBox(this.name, this.cells);

  int maxX() {
    int x = 0;
    cells.forEach((c) {
      x = max(c.xpos, x);
    });
    return x;
  }

  int maxY() {
    int y = 0;
    cells.forEach((c) {
      y = max(c.ypos, y);
    });
    return y;
  }

  bool includes(Cell cell) => cells.contains(cell);

  bool canAdd(Cell cell, int value, Map<Cell, int> fixedCells) {
    if (!includes(cell)) {
      return false;
    }
    return !cells.any((eachCell) => fixedCells[eachCell] == value);
  }

  Set<int> possibleValues(Cell cell, Set<int> values, CellAccess game) {
    Set<int> result = Set.from(values);
    cells.forEach((eachCell) {
      if (eachCell != cell) {
        game.valueIfKnown(eachCell, (value) => result.remove(value));
      }
    });
    return result;
  }

  Iterable<Move> _findMoves(Map<Cell, Set<int>> options) {
    Map<int, List<Cell>> cellsPerValue = {};
    for (var eachCell in cells) {
      var values = options[eachCell] ?? <int>{};
      for (var value in values) {
        if (cellsPerValue.containsKey(value)) {
          cellsPerValue[value].add(eachCell);
        } else {
          cellsPerValue[value] = [ eachCell];
        }
      }
    }
    return cellsPerValue.entries
        .where((e) => e.value.length == 1)
        .map((e) => Move(e.value[0], e.key, MoveReason.ONLY_PLACE));
  }

  Move findMove(Map<Cell, Set<int>> options) {
    var iter = _findMoves(options);
    return iter.isEmpty ? null : iter.first;
  }

  Set<Move> findMoves(Map<Cell, Set<int>> options) {
    return _findMoves(options).toSet();
  }
}

class SudokuGame extends CellAccess {

  final SudokuBoard board;
  final Map<Cell, int> fixedCells;

  static SudokuGame newFromArray(List<List<int>> rows) {
    return (new SudokuGameBuilder(SudokuBoard.default9x9())
      ..fixWithArray(rows))
        .newGame();
  }

  const SudokuGame(this.board, this.fixedCells);

  @override
  int valueAt(Cell cell) => fixedCells[cell] ?? -1;

  bool isFixed(Cell cell) => fixedCells.containsKey(cell);

  Map<Cell, Set<int>> optionsPerCell() => calcOptionsPerCell(this);

  Map<Cell, Set<int>> calcOptionsPerCell(CellAccess gameState) {
    Map<Cell, Set<int>> map = {};
    forOpenCells((eachCell) {
      map[eachCell] = board.possibleValues(eachCell, gameState);
    });
    return map;
  }

  void forOpenCells(func(Cell)) {
    board.forRelevantCells((eachCell) {
      if (!fixedCells.containsKey(eachCell)) {
        func(eachCell);
      }
    });
  }
}
