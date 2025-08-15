from .models.sudoku import Sudoku4x4

fn hash(a: Int, b: Int, c: Int, d: Int) -> Int:
  return a * 1000 + b * 100 + c * 10 + d

fn hash_box(grid: Sudoku4x4, box_index: Int) -> Int:
  var start_row = (box_index // 2) * 2 
  var start_col = (box_index % 2) * 2

  var box = List[Int](0, 0, 0, 0)
  for row in range(2):
    for col in range(2):
      box[row * 2 + col] = grid.get(row + start_row, col + start_col)

  return hash(box[0], box[1], box[2], box[3])

fn hash_sudoku(grid: Sudoku4x4) -> Int:
  return hash(grid.get(0,0), grid.get(0,3), grid.get(3, 0), grid.get(3,3))
