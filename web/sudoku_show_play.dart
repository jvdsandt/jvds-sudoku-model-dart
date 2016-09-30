import "sudoku_model.dart";
import "sudoku_database.dart";

void main() {
  var game = SudokuGame.newFromArray(standard9x9game);
  showPlay(game);
}

void showPlay(SudokuGame game) {
  var gamePlay = game;
  var moveCount = 0;
  print("game:\n" + game.toString());
  while (!gamePlay.isSolved()) {
    print('');
    gamePlay = gamePlay.doNextMove();
    moveCount++;
    print("move ${moveCount}: " + gamePlay.lastMove.toString());
    print(gamePlay.toString());
  }
}
