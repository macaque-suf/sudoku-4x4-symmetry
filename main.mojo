from mod.count_occurance import count
from mod.aggregates import hash_box, hash_sudoku

fn main() raises:
  var classes = count().values()
  for sudokus in classes:
    var prime = sudokus[0]
    prime.print_grid()
