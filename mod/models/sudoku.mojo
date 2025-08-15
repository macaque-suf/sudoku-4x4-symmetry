# -------------------------------------------------------------------
# Sudoku4x4 — compact representation of a 4×4 Sudoku grid
# -------------------------------------------------------------------
# Backing storage:
#   - A SIMD vector of 16 signed 8-bit integers (int8).
#   - Flattened row-major order: index = row * 4 + col.
#   - Values:
#       0 → empty cell
#       1–4 → digits
#
# Traits:
#   - Copyable & Movable → lightweight value semantics
#   - Stringable         → defines __str__ for easy printing
# -------------------------------------------------------------------
struct Sudoku4x4(Copyable & Movable & Stringable):
    var grid: SIMD[DType.int8, 16]

    # ---- Constructors ----
    fn __init__(out self):
        """Initialize empty grid (all zeros)."""
        self.grid = SIMD[DType.int8, 16](0)

    fn __init__(out self, values: SIMD[DType.int8, 16]):
        """Initialize with given SIMD values."""
        self.grid = values

    # ---- Accessors ----
    fn get(self, row: Int, col: Int) -> Int:
        """Get value at position (row, col)."""
        return Int(self.grid[row * 4 + col])

    fn set(mut self, row: Int, col: Int, value: Int8):
        """Set value at position (row, col)."""
        self.grid[row * 4 + col] = value

    # ---- Debug / Display ----
    fn print_grid(self):
        """Print the grid in a human-friendly 4×4 format."""
        for i in range(4):
            for j in range(4):
                print(self.get(i, j), " ", end="")
            print()
        print()

    fn __str__(self) -> String:
        """
        Flatten the grid into a compact string encoding.
        Row-major order, digits concatenated, '.' used as row delimiter.
        Example:
            1234.2413.3142.4321.
        """
        var str = ""
        for i in range(4):
            for j in range(4):
                str += String(self.get(i, j))
            str += "."
        return str

    # ---- Validation helpers ----
    fn is_valid_row(self, row: Int, ignore_incomplete: Bool = False) -> Bool:
        """
        Check if a row obeys Sudoku rules:
          - Digits 1–4 appear at most once.
          - If ignore_incomplete = False, zeros are treated as invalid.
        """
        var seen = SIMD[DType.int8, 8](False)  # seen[val] = 1 if digit already found
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
        """Same logic as is_valid_row, but checks a column."""
        var seen = SIMD[DType.int8, 8](False)
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
        """
        Check if a 2×2 box (indexed by box_row, box_col) is valid.
          - box_row ∈ {0,1}, box_col ∈ {0,1}
          - Top-left cell = (box_row*2, box_col*2)
        """
        var seen = SIMD[DType.int8, 8](False)
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

    # ---- Global validation ----
    fn is_valid(self, ignore_incomplete: Bool = False) -> Bool:
        """
        Check if the entire grid satisfies Sudoku constraints:
          - All 4 rows valid
          - All 4 columns valid
          - All 4 (2×2) boxes valid
        """
        # Check rows
        for row in range(4):
            if not self.is_valid_row(row, ignore_incomplete):
                return False

        # Check columns
        for col in range(4):
            if not self.is_valid_col(col, ignore_incomplete):
                return False

        # Check boxes
        for box_row in range(2):
            for box_col in range(2):
                if not self.is_valid_box(box_row, box_col, ignore_incomplete):
                    return False

        return True

