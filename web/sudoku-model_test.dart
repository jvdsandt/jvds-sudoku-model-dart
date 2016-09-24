import "package:test/test.dart";

import "sudoku-model.dart";

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
    List<List<int>> rows = [
      [ 1, 0, 0, 0, 0, 7, 0, 9, 0 ],
      [ 0, 3, 0, 0, 2, 0, 0, 0, 8 ],
      [ 0, 0, 9, 6, 0, 0, 5, 0, 0 ],
      [ 0, 0, 5, 3, 0, 0, 9, 0, 0 ],
      [ 0, 1, 0, 0, 8, 0, 0, 0, 2 ],
      [ 6, 0, 0, 0, 0, 4, 0, 0, 0 ],
      [ 3, 0, 0, 0, 0, 0, 0, 1, 0 ],
      [ 0, 4, 0, 0, 0, 0, 0, 0, 7 ],
      [ 0, 0, 7, 0, 0, 0, 3, 0, 0 ] ];
    var game = SudokuGame.newFromArray(rows);
    expect(game.isFixed(new SudokuCell(6, 1)), equals(true));
    expect(game.isFixed(new SudokuCell(7, 1)), equals(false));
  });
}