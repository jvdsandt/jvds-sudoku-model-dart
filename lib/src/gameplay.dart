import 'value_classes.dart';

abstract class GameState extends CellAccess {
  final Map<Cell, Set<int>> optionsPerCell;

  GameState(this.optionsPerCell);

  SudokuGame getGame();

  GameState getPreviousState();

  int valueAt(Cell cell) => getSolvedCells()[cell] ?? getGame().valueAt(cell);

  Map<Cell, int> getSolvedCells() => {};

  getOptions(Cell c) => optionsPerCell[c];

  int numberOfCellsToSolve() => optionsPerCell.length;

  bool isSolved() => numberOfCellsToSolve() == 0;

  bool isPossibleMove(Cell c, int value) {
    return optionsPerCell.containsKey(c) && optionsPerCell[c].contains(value);
  }

  bool isInitialState() => false;

  bool isBadMoveState() => false;

  SudokuBoard getBoard() => getGame().board;

  /**
   * All open cells should have at least one option. Otherwise
   * we are in an invalid state!
   */
  bool hasValidOptions() => optionsPerCell.values.every((e) => !e.isEmpty);

  /**
   * If there is a cell that can only contain a single value
   * than answer a move to fill this cell. Otherwise answer null.
   */
  Move getFirstSingleOptionMove() {
    return optionsPerCell.entries
        .where((e) => e.value.length == 1)
        .map((e) => Move(e.key, e.value.toList()[0], MoveReason.ONLY_OPTION))
        .firstWhere((e) => true, orElse: () => null);
  }

  /**
   * If there is a cell which is the only place where a value can be,
   * than answer a move to fill this cell. Otherwise answer nil.
   */
  Move getOnlyPlaceMove() {
    for (var b in getBoard().boxes) {
      var move = b.findMove(optionsPerCell);
      if (move != null) {
        return move;
      }
    }
    return null;
  }

  List<Move> getPossibleMoves() {
    var moves = optionsPerCell.entries
        .where((e) => e.value.length == 1)
        .map((e) => Move(e.key, e.value.toList()[0], MoveReason.ONLY_OPTION))
        .toList();
    for (var b in getBoard().boxes) {
      moves.addAll(b.findMoves(optionsPerCell));
    }
    // remove duplicates
    var cells = <Cell>{};
    var uniqueMoves = <Move>[];
    for (Move m in moves) {
      if (!cells.contains(m.cell)) {
        uniqueMoves.add(m);
        cells.add(m.cell);
      }
    }
    uniqueMoves.sort();
    return uniqueMoves;
  }

  Move takeGuess() {
    Cell cell = null;
    Set<int> values = null;
    for (var entry in optionsPerCell.entries) {
      if (!entry.value.isEmpty &&
          (values == null || values.length > entry.value.length)) {
        cell = entry.key;
        values = entry.value;
      }
    }
    return Move(cell, values.toList()[0], MoveReason.GUESS);
  }
}

class GameInitialState extends GameState {
  final SudokuGame game;

  GameInitialState(this.game) : super(game.optionsPerCell());

  @override
  SudokuGame getGame() => game;

  @override
  GameState getPreviousState() {
    throw UnimplementedError("No previous state");
  }

  @override
  int valueAt(Cell cell) => game.valueAt(cell);

  @override
  bool isInitialState() => true;
}

abstract class GameActiveState extends GameState {
  final SudokuGame game;
  final GameState previousState;

  GameActiveState(options, previousState)
      : this.game = previousState.getGame(),
        this.previousState = previousState,
        super(options);

  @override
  SudokuGame getGame() => game;

  @override
  GameState getPreviousState() => previousState;
}

class GameBadMoveState extends GameActiveState {
  final Move badMove;

  static Map<Cell, Set<int>> _withoutBadMove(
      Map<Cell, Set<int>> options, Move badMove) {
    var values = options[badMove.cell];
    if (values == null || !values.contains(badMove.value)) {
      throw ArgumentError("Cannot process bad move " + badMove.toString());
    }
    // remove the bad move as a valid option
    options[badMove.cell] = Set.of(values.where((e) => e != badMove.value));
    return options;
  }

  GameBadMoveState(GameState prevState, this.badMove)
      : super(_withoutBadMove(prevState.optionsPerCell, badMove), prevState);

  @override
  Map<Cell, int> getSolvedCells() => previousState.getSolvedCells();

  @override
  bool isBadMoveState() => true;
}

class GameMoveState extends GameActiveState {
  final Move lastMove;
  final Map<Cell, int> solvedCells;

  GameMoveState(GameState prevState, Move move) : super(prevState.getBoard().)

}
