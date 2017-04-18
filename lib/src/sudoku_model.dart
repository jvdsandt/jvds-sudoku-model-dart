import 'dart:math';

abstract class SudokuGameBase {
  final SudokuOptionsPerCell optionsPerCell;

  const SudokuGameBase(this.optionsPerCell);

  SudokuGame get game;

  SudokuBoard get board => game.board;

  int valueAt(SudokuCell cell);

  Map<SudokuCell, int> get solvedCells => {};

  bool isSolved() => false;

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
    var newSolvedCells = new Map.from(solvedCells)
      ..[nextMove.cell] = nextMove.value;

    return new SudokuAutoGame(
        this, nextMove, newOptions, newSolvedCells, guessed);
  }
}

class SudokuGame extends SudokuGameBase {
  final SudokuBoard board;
  final Map<SudokuCell, int> fixedCells;
  final int numberOfCellsToSolve;

  static SudokuGame newFromArray(List<List<int>> rows) {
    return (new SudokuGameBuilder(SudokuBoard.default9x9())..fixWithArray(rows))
        .newGame();
  }

  SudokuGame(SudokuBoard board, Map<SudokuCell, int> fixedCells)
      : super(SudokuOptionsPerCell.create(board, fixedCells)),
        this.board = board,
        this.fixedCells = fixedCells,
        this.numberOfCellsToSolve =
            board.relevantCells().length - fixedCells.length;

  @override
  SudokuGame get game => this;

  @override
  int valueAt(SudokuCell cell) => fixedCells[cell];

  bool isFixed(SudokuCell cell) => fixedCells.containsKey(cell);
}

class SudokuGamePlay extends SudokuGameBase {
  final SudokuGame game;
  final SudokuGameBase previousPlay;
  final Map<SudokuCell, int> solvedCells;
  final SudokuMove lastMove;

  SudokuGamePlay(SudokuGameBase previousPlay, SudokuMove lastMove,
      SudokuOptionsPerCell options, Map<SudokuCell, int> solvedCells)
      : super(options),
        this.game = previousPlay.game,
        this.previousPlay = previousPlay,
        this.solvedCells = solvedCells,
        this.lastMove = lastMove;

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
      : super(previousPlay, lastMove, options, solvedCells),
        this.guessed = guessed;
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

class SudokuOptionsPerCell {
  final Map<SudokuCell, List<int>> map;

  const SudokuOptionsPerCell(this.map);

  static create(SudokuBoard board, Map<SudokuCell, int> fixedCells) {
    var options = {};
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
        : new SudokuMove(cell, map[cell].first, 'only option');
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
    return new SudokuMove(cell, minValues.first, "guess from ${minValues}");
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

  List<int> possibleValues(SudokuCell cell, Map<SudokuCell, int> fixedCells) {
    List<int> values = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    boxesFor(cell, (eachBox) {
      values = eachBox.possibleValues(cell, values, fixedCells);
    });
    return values;
  }

  void cellsSharingBoxWith(SudokuCell cell, func(SudokuCell)) {
    Set cellSet = new Set();
    for (var box in boxes) {
      if (box.includes(cell)) {
        for (var eachCell in box.cells) {
          if (eachCell != cell && !cellSet.contains(eachCell)) {
            func(eachCell);
            cellSet.add(eachCell);
          }
        }
      }
    }
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

  SudokuMove findMove(SudokuOptionsPerCell openCellsWithValues) {
    Map<int, List<SudokuCell>> cellsPerValue = {};
    for (var cell in cells) {
      if (openCellsWithValues.containsCell(cell)) {
        for (var value in openCellsWithValues[cell]) {
          cellsPerValue.putIfAbsent(value, () => []).add(cell);
        }
      }
    }
    var value = cellsPerValue.keys.firstWhere(
        (val) => cellsPerValue[val].length == 1,
        orElse: () => null);
    return value == null
        ? null
        : new SudokuMove(
            cellsPerValue[value].first, value, "only option in box ${name}");
  }

  List<int> possibleValues(
      SudokuCell cell, List<int> values, Map<SudokuCell, int> fixedCells) {
    var result = values;
    for (var eachCell in cells) {
      if (eachCell != cell) {
        var value = fixedCells[eachCell];
        if (value != null) {
          result = new List.from(result)..remove(value);
        }
        ;
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
  int get hashCode => (xpos * 10) + ypos;

  @override
  String toString() => "${xpos}@${ypos}";
}

class SudokuMove {
  final SudokuCell cell;
  final int value;
  final String text;

  const SudokuMove(this.cell, this.value, this.text);

  @override
  String toString() {
    return "${cell} -> ${value} (${text})";
  }
}
