import "package:test/test.dart";

import "../lib/src/sudoku_database.dart";

import '../lib/src/value_classes.dart';

/**
 * Dummy game for testing.
 */
class DummyGame extends CellAccess {

  final Map<Cell, int> cellValues;

  DummyGame(this.cellValues);

  int valueAt(Cell c) {
    return cellValues[c] ?? -1;
  }
}

void main() {

  test("Create Cell", () {
    var cell = new Cell(4, 5);
    expect(cell.xpos, equals(4));
    expect(cell.ypos, equals(5));
    expect(cell, equals(Cell(4, 5)));
    expect(cell.toString(), equals("4@5"));
    expect(cell.compareTo(Cell(4, 5)), equals(0));
    expect(cell.compareTo(Cell(5, 5)), equals(-1));
    expect(cell.compareTo(Cell(5, 3)), equals(2));
  });

  test("Create Move", () {
    var move = Move(Cell(5, 5), 9, MoveReason.MANUAL);
    expect(move.toString(), equals("5@5 -> 9 (MoveReason.MANUAL)"));
  });

  test("Create Box", () {
    var c1 = Cell(4, 5);
    var c2 = Cell(7, 5);
    var box = SudokuBox("test", [c1, c2]);
    expect(box.name, equals("test"));
    expect(box.maxX(), equals(7));
    expect(box.maxY(), equals(5));
    expect(box.includes(Cell(7, 5)), true);
    expect(box.includes(Cell(7, 6)), false);
  });

  test("Box possibleValues", () {
    var box = SudokuBox("test", [Cell(1,1), Cell(2,1), Cell(1,2), Cell(2,2)]);
    var game = DummyGame({ Cell(1,1): 3 });
    expect(
      box.possibleValues(Cell(2, 1), { 1, 2, 3, 4 }, game),
      equals({ 1, 2, 4 })
    );
    expect(
      box.possibleValues(Cell(2, 1), { 1 }, game),
      equals({ 1 })
    );
    expect(
      box.possibleValues(Cell(2, 1), { 3 }, game),
      equals(<int>{})
    );
  });

  test("Create 9x9 board", () {
    var b = SudokuBoard.default9x9();
    expect(b.boxes.length, equals(27));
    var firstBox = b.boxes.first;
    expect(firstBox.cells.length, equals(9));
    expect(firstBox.name, equals("row-1"));
    expect(firstBox.maxX(), equals(9));
    expect(firstBox.maxY(), equals(1));
    expect(b.boxes.last.cells.length, equals(9));
  });

  test("Board possibleValues", () {
    var b = SudokuBoard.default9x9();
    var game = DummyGame({ Cell(1,1): 3, Cell(2,2): 4, Cell(3,3): 5, Cell(1,9): 9 });
    expect(b.possibleValues(Cell(2,1), game), equals({ 1, 2, 6, 7, 8, 9 }));
    expect(b.possibleValues(Cell(1,2), game), equals({ 1, 2, 6, 7, 8 }));
  });

  test("Build game", () {
    var game = SudokuGame.newFromArray(standard9x9game);
    expect(game.isFixed(Cell(6, 1)), equals(true));
    expect(game.isFixed(Cell(7, 1)), equals(false));
    expect(game.valueAt(Cell(1, 8)), equals(-1));
    var options = game.calcOptionsPerCell(game);
    expect(options[Cell(1, 8)], equals([2, 5, 8, 9]));
  });
}