import 'package:jvds_sudoku_dart/jvds_sudoku_model.dart';

void main() {
  var game = SudokuGame.newFromArray(standard9x9game);
  showPlay(game);
}

void showPlay(SudokuGame game) {
  var player = AutoPlayer(game);
  var moveCount = 0;
  print("game:\n" + game.toString());
  while (!player.isSolved()) {
    print('');
    player.doAutoMove();
    moveCount++;
    print("move ${moveCount}: " + player.currentStep.getLastMove().toString());
    print(player.currentStep.toString());
  }
}
