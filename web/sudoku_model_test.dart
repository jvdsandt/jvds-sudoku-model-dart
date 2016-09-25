import "package:test/test.dart";

import "sudoku_model.dart";
import "sudoku_database.dart";

void main() {

  test("Create SudokuCell", () {
    var cell = new SudokuCell(4, 5);
    expect(cell.xpos, equals(4));
    expect(cell.ypos, equals(5));
  });

  test("Create SudokuBox", () {
    var c1 = new SudokuCell(4, 5);
    var c2 = new SudokuCell(5, 5);
    var box = new SudokuBox("test", [c1, c2]);
    expect(box.name, equals("test"));
    expect(box.maxX(), equals(5));
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

  test("Build game", () {
    var game = SudokuGame.newFromArray(standard9x9game);
    expect(game.isFixed(new SudokuCell(6, 1)), equals(true));
    expect(game.isFixed(new SudokuCell(7, 1)), equals(false));
    expect(game.optionsPerCell[new SudokuCell(1, 8)], equals([2, 5, 8, 9]));
  });

  test("Solve simple game", () {
    var game = SudokuGame.newFromArray(simple9x9game);
    print("game = " + game.toString());
    var solvedGame = game.solve();
    print("solvedgame = " + solvedGame.toString());
  });

  test("Solve standard game", () {
    var game = SudokuGame.newFromArray(standard9x9game);
    print("game = " + game.toString());
    var solvedGame = game.solve();
    print("solvedgame = " + solvedGame.toString());
  });
}