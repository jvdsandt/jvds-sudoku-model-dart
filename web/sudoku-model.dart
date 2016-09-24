import 'dart:math';

abstract class SudokuGameBase {
  Map<SudokuCell, List<int>> optionsPerCell;

  SudokuGame get game;

  SudokuBoard get board => game.board;

  int valueAt(SudokuCell cell);

  void valueIfKnown(SudokuCell cell, func(int)) {
    int value = valueAt(cell);
    if (value != null) {
      func(value);
    }
  }

  SudokuMove firstSingleOption() {
    optionsPerCell.forEach((cell, values) {
      if (values.length == 1) {
        return new SudokuMove(cell, values.first);
      }
    });
    return null;
  }

  SudokuMove doNextMove() {
    SudokuMove move = firstSingleOption();
    if (move != null) {

    }
    for (var box in board.boxes) {

    }
  }
}

class SudokuGame extends SudokuGameBase {
  SudokuBoard board;
  Map<SudokuCell, int> fixedCells;
  int numberOfCellsToSolve;

  static SudokuGame newFromArray(List<List<int>> rows) {
    return (new SudokuGameBuilder(SudokuBoard.default9x9())..fixWithArray(rows))
        .newGame();
  }

  SudokuGame(SudokuBoard board, Map<SudokuCell, int> fixedCells) {
    this.board = board;
    this.fixedCells = fixedCells;
    this.numberOfCellsToSolve =
        board.relevantCells().length - fixedCells.length;
    initOptionsPerCell();
  }

  @override
  SudokuGame get game => this;

  @override
  int valueAt(SudokuCell cell) => fixedCells[cell];

  bool isFixed(SudokuCell cell) => fixedCells.containsKey(cell);

  void initOptionsPerCell() {
    optionsPerCell = {};
    for (var cell in board.relevantCells()) {
      if (!fixedCells.containsKey(cell)) {
        optionsPerCell[cell] = board.possibleValues(cell, this);
      }
    }
  }
}

class SudokuGameBuilder {
  SudokuBoard board;
  Map<SudokuCell, int> fixedCells = {};

  SudokuGameBuilder(this.board);

  void fix(SudokuCell cell, int value) {
    fixedCells[cell] = value;
  }

  void fixWithArray(List<List<int>> rows) {
    for (int y = 0; y < rows.length; y++) {
      for (int x = 0; x < rows[y].length; x++) {
        if (rows[y][x] > 0) {
          fix(new SudokuCell(x + 1, y + 1), rows[y][x]);
        }
      }
    }
  }

  SudokuGame newGame() {
    return new SudokuGame(board, new Map.from(fixedCells));
  }
}

class SudokuBoard {
  int maxX;
  int maxY;
  List<SudokuBox> boxes;

  static SudokuBoard default9x9() {
    return (new SudokuBoardBuilder()..initStandard(9, 9)).newBoard();
  }

  SudokuBoard(List<SudokuBox> boxes) {
    this.boxes = boxes;
    var mx = 0;
    var my = 0;
    boxes.forEach((box) {
      mx = max(mx, box.maxX());
      my = max(my, box.maxY());
    });
    this.maxX = mx;
    this.maxY = my;
  }

  Set<SudokuCell> relevantCells() => boxes.fold(new Set(), (Set coll, box) {
        coll.addAll(box.cells);
        return coll;
      });

  void boxesFor(SudokuCell cell, func(SudokuBox b)) {
    for (var box in boxes) {
      if (box.includes(cell)) {
        func(box);
      }
    }
  }

  List<int> possibleValues(SudokuCell cell, SudokuGameBase game) {
    List<int> values = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    boxesFor(cell, (eachBox) {
      values = eachBox.possibleValues(cell, values, game);
    });
    return values;
  }
}

class SudokuBox {
  final String name;
  final List<SudokuCell> cells;

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

  SudokuMove findMove(Map<SudokuCell, List<int>> openCellsWithValues) {
    Map<int, List<SudokuCell>> cellsPerValue = {};
    for (var cell in cells) {
      if (openCellsWithValues.containsKey(cell)) {
        for (var value in openCellsWithValues[cell]) {
          cellsPerValue.putIfAbsent(value, () => []).add(cell);
        }
      }
    }
    cellsPerValue.forEach((value, cells) {
      if (cells.length == 1) {
        return new SudokuMove(cells.first, value);
      }
    });
    return null;
  }

  List<int> possibleValues(SudokuCell cell, List<int> values, SudokuGame game) {
    var result = values;
    for (var eachCell in cells) {
      if (eachCell != cell) {
        game.valueIfKnown(eachCell, (int value) {
          result = new List.from(result)..remove(value);
        });
      }
    }
    return result;
  }

  bool includes(SudokuCell cell) => cells.contains(cell);
}

class SudokuBoardBuilder {
  List<SudokuBox> boxes = [];

  void initStandard(int maxX, int maxY) {
    for (var i = 1; i <= maxY; i++) {
      addBox("row-${i}", new SudokuCell(1, i), new SudokuCell(maxX, i));
    }
    for (var i = 1; i <= maxX; i++) {
      addBox("column-${i}", new SudokuCell(i, 1), new SudokuCell(i, maxY));
    }
    for (var ypos = 1; ypos <= maxY; ypos = ypos + 3) {
      for (var xpos = 1; xpos <= maxX; xpos = xpos + 3) {
        addBox("box-${xpos}x${ypos}", new SudokuCell(xpos, ypos),
            new SudokuCell(xpos + 2, ypos + 2));
      }
    }
  }

  void addBox(String name, SudokuCell fromCell, SudokuCell toCell) {
    List<SudokuCell> cells = [];
    for (var y = fromCell.ypos; y <= toCell.ypos; y++) {
      for (var x = fromCell.xpos; x <= toCell.xpos; x++) {
        cells.add(new SudokuCell(x, y));
      }
    }
    boxes.add(new SudokuBox(name, cells));
  }

  SudokuBoard newBoard() {
    return new SudokuBoard(new List.from(boxes));
  }
}

class SudokuCell {
  final int xpos;
  final int ypos;

  const SudokuCell(this.xpos, this.ypos);

  @override
  bool operator ==(Object other) =>
      other is SudokuCell && other.xpos == xpos && other.ypos == ypos;

  @override
  int get hashCode => xpos;

  @override
  String toString() => "${xpos}@${ypos}";
}

class SudokuMove {
  final SudokuCell cell;
  final int value;

  const SudokuMove(this.cell, this.value);
}
