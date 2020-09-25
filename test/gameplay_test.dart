import "package:test/test.dart";

import "../lib/src/sudoku_database.dart";
import '../lib/src/gameplay.dart';
import '../lib/src/value_classes.dart';

testGame(SudokuGame game) {
  var player = AutoPlayer(game);
  player.solve();
}

void main() {

  test("All very hard games", () {
    veryHardGameLines.forEach((line) {
      var game = SudokuGame.newFromLine(line);
      testGame(game);
    });
  });
}