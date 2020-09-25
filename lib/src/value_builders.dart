import 'value_classes.dart';

final codeUnit0 = '0'.codeUnitAt(0);
final codeUnit9 = '9'.codeUnitAt(0);

class SudokuBoardBuilder {

  List<SudokuBox> boxes = [];

  static SudokuBoard default9x9() {
    var builder = SudokuBoardBuilder();
    builder.initStandard(9, 9);
    return builder.newBoard();
  }

  void initStandard(int maxX, int maxY) {
    for (var i = 1; i <= maxY; i++) {
      addBox("row-${i}", new Cell(1, i), new Cell(maxX, i));
    }
    for (var i = 1; i <= maxX; i++) {
      addBox("column-${i}", new Cell(i, 1), new Cell(i, maxY));
    }
    for (var ypos = 1; ypos <= maxY; ypos = ypos + 3) {
      for (var xpos = 1; xpos <= maxX; xpos = xpos + 3) {
        addBox("box-${xpos}x${ypos}", new Cell(xpos, ypos),
            new Cell(xpos + 2, ypos + 2));
      }
    }
  }

  void addBox(String name, Cell fromCell, Cell toCell) {
    List<Cell> cells = [];
    for (var y = fromCell.ypos; y <= toCell.ypos; y++) {
      for (var x = fromCell.xpos; x <= toCell.xpos; x++) {
        cells.add(Cell(x, y));
      }
    }
    boxes.add(SudokuBox(name, List.unmodifiable(cells)));
  }

  SudokuBoard newBoard() {
    return SudokuBoard(List.unmodifiable(boxes));
  }
}

class SudokuGameBuilder {
  SudokuBoard board;
  Map<Cell, int> fixedCells = {};

  SudokuGameBuilder(this.board);

  void fix(Cell cell, int value) {
    fixedCells[cell] = value;
  }

  void fixWithArray(List<List<int>> rows) {
    for (int y = 0; y < rows.length; y++) {
      for (int x = 0; x < rows[y].length; x++) {
        if (rows[y][x] > 0) {
          fix(Cell(x + 1, y + 1), rows[y][x]);
        }
      }
    }
  }

  void initFromNumberLine(String numberLine) {
    for (int y = 0; y < board.maxY; y++) {
      for (int x = 0; x < board.maxX; x++) {
        var value = numberLine.codeUnitAt((y * board.maxX) + x);
        if (value < codeUnit0 || value > codeUnit9) {
          throw ArgumentError("Invalid cell value");
        }
        if (value != codeUnit0) {
          fix(Cell(x + 1, y + 1), value - codeUnit0);
        }
      }
    }
  }

  SudokuGame newGame() {
    return new SudokuGame(board, Map.from(fixedCells));
  }
}