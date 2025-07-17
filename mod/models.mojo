struct Sudoku4x4(Copyable & Movable & Stringable):
  var grid: SIMD[DType.int8, 16]

  fn __init__(out self):
    """Initialize empty grid."""
    self.grid = SIMD[DType.int8, 16](0)

  fn __init__(out self, values: SIMD[DType.int8, 16]):
    """Initialize with given values."""
    self.grid = values

  fn get(self, row: Int, col: Int) -> Int:
    """Get value at position (row, col)."""
    return Int(self.grid[row * 4 + col])

  fn set(mut self, row: Int, col: Int, value: Int8):
    """Set value at position (row, col)."""
    self.grid[row * 4 + col] = value

  fn print_grid(self):
    """Print the grid in a readable format."""
    for i in range(4):
      for j in range(4):
        print(self.get(i, j), " ", end="")
      print()
    print()

  fn __str__(self) -> String:
    var str = ""
    for i in range(4):
      for j in range(4):
        str += String(self.get(i, j))
      str+= "."
    return str

  fn is_valid_row(self, row: Int, ignore_incomplete: Bool = False) -> Bool:
    """Check if a row contains digits 1-4 exactly once."""
    var seen = SIMD[DType.int8, 8](False)  # Index 0 unused
    for col in range(4):
      var val = self.get(row, col)
      if (val < 1 and not ignore_incomplete) or val > 4:
        return False
      if seen[val]:
        return False
      if val > 0:
        seen[val] = True
    return True

  fn is_valid_col(self, col: Int, ignore_incomplete: Bool = False) -> Bool:
    """Check if a column contains digits 1-4 exactly once."""
    var seen = SIMD[DType.int8, 8](False)  # Index 0 unused
    for row in range(4):
      var val = self.get(row, col)
      if (val < 1 and not ignore_incomplete) or val > 4:
        return False
      if seen[val]:
        return False
      if val > 0:
        seen[val] = True
    return True

  fn is_valid_box(self, box_row: Int, box_col: Int, ignore_incomplete: Bool = False) -> Bool:
    """Check if a 2x2 box contains digits 1-4 exactly once."""
    var seen = SIMD[DType.int8, 8](False)  # Index 0 unused
    for i in range(2):
      for j in range(2):
        var val = self.get(box_row * 2 + i, box_col * 2 + j)
        if (val < 1 and not ignore_incomplete) or val > 4:
          return False
        if seen[val]:
          return False
        if val > 0:
          seen[val] = True
    return True

  fn is_valid(self, ignore_incomplete: Bool = False) -> Bool:
    """Check if the grid satisfies all Sudoku constriants."""
    # Check all rows
    for row in range(4):
      if not self.is_valid_row(row, ignore_incomplete):
        return False

    # Check all columns
    for col in range(4):
      if not self.is_valid_col(col, ignore_incomplete):
        return False

    # Check all 2x2 boxes
    for box_row in range(2): 
      for box_col in range(2): 
        if not self.is_valid_box(box_row, box_col, ignore_incomplete): 
          return False

    return True

