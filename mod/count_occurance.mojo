from .models import Sudoku4x4

fn backtrack(mut grid: Sudoku4x4, row: Int, col: Int) -> Dict[String, Sudoku4x4]:
  """
  Generates all valid completed 4x4 Sudoku grids using backtracking.
  
  This is a classic constraint satisfaction problem solver that systematically
  tries all possibilities while pruning invalid branches early. It fills the
  grid cell by cell, left-to-right, top-to-bottom.
  
  Algorithm Overview:
  1. Try each value 1-4 in the current cell
  2. Check if the grid is still valid with this value
  3. If valid, recursively fill the next cell
  4. If we reach the end (bottom-right), we've found a solution
  5. Backtrack by removing the value and trying the next one
  
  Parameters:
  - grid: The partially filled Sudoku grid (modified in-place)
  - row, col: Current cell position being filled (0-indexed)
  
  Returns:
  - Dictionary mapping grid strings to Sudoku4x4 objects
  - Using strings as keys ensures uniqueness (no duplicate solutions)
  
  Why use a dictionary?
  - Automatically handles duplicates (same grid state from different paths)
  - String representation serves as a unique identifier
  - Easy to merge results from recursive calls
  
  Time Complexity: O(4^n) where n is number of empty cells
  - In worst case, we try all 4 values for each empty cell
  - Early pruning via is_valid() significantly reduces actual complexity
  
  Space Complexity: O(n) for recursion depth + O(s) for storing s solutions
  """

  results_dict = Dict[String, Sudoku4x4]()

  # Check if any of the numbers can be placed
  for candidate in range(1,5):
    grid.set(row, col, candidate)
    if grid.is_valid(ignore_incomplete = True):
      var solutions: Dict[String, Sudoku4x4]
      # Check if this is the bottom right corner
      if row != 3 or col != 3:
        var index = (row * 4 + col) + 1
        solutions = backtrack(grid, index // 4, index % 4)
      else:
        solutions = { String(grid): grid }

      results_dict.update(solutions)
  
  # Unset this after we've finished counting
  grid.set(row, col, 0)

  return results_dict

fn relabel(grid: Sudoku4x4, perm: List[Int]) -> Sudoku4x4:
  """
  Applies a permutation to the values (labels) in the Sudoku grid.
  
  This is a fundamental transformation because the actual numbers 1-4 in Sudoku
  are arbitrary labels. Any permutation of these labels preserves the puzzle's
  logical structure.
  
  How it works:
  - perm is a list where perm[i-1] gives the new value for old value i
  - For example, perm=[2,3,4,1] means: 1->2, 2->3, 3->4, 4->1
  
  Why this matters:
  - Two Sudoku puzzles that differ only by relabeling are considered equivalent
  - There are 4! = 24 possible relabelings for a 4x4 Sudoku
  - Finding canonical forms requires checking all relabelings
  
  Example:
  Grid:         perm=[4,3,2,1]    Result:
  1 2 3 4       (1->4,2->3,...)  4 3 2 1
  2 1 4 3       -------->        3 4 1 2
  3 4 1 2                        2 1 4 3
  4 3 2 1                        1 2 3 4
  
  Note: Empty cells (value 0) are not transformed
  """
  var copy = grid
  for row in range(4):
    for col in range(4):
      var old_val = grid.get(row, col)
      if old_val > 0:
        copy.set(row, col, perm[old_val - 1])
  return copy

fn generate_all_permutations() -> List[List[Int]]:
  """
  Generates all 24 permutations of the values [1, 2, 3, 4].
  
  This is a brute-force approach using 4 nested loops, each selecting
  a different unused value. While not the most elegant algorithm, it's
  clear and sufficient for the small fixed size.
  
  Mathematical background:
  - There are 4! = 4×3×2×1 = 24 permutations of 4 elements
  - Each permutation represents a way to relabel the Sudoku values
  - These are all elements of the symmetric group S4
  
  Algorithm visualization:
  - First position: 4 choices (i)
  - Second position: 3 remaining choices (j != i)
  - Third position: 2 remaining choices (k != i,j)
  - Fourth position: 1 remaining choice (h != i,j,k)
  
  Example output includes:
  [1,2,3,4] - identity permutation
  [1,2,4,3] - swaps 3 and 4
  [4,3,2,1] - complete reversal
  ... (21 more permutations)
  
  Time complexity: o(4!) = o(24) = O(1)
  Space complexity: o(24) for storing all permutations
  """
  var perms = List[List[Int]]()

  for i in range(1, 5):
    for j in range(1, 5):
      if i == j:
        continue
      for k in range(1, 5):
        if i == k or j == k:
          continue
        for h in range(1, 5):
          if h == i or h == j or h == k:
            continue
          perms.append(List[Int](i,j,k,h))
    
  return perms


fn count() -> Dict[String, List[Sudoku4x4]]:
  var blank_grid = Sudoku4x4()
  var counted_space = backtrack(blank_grid, 0, 0)
  print("counted_space: ", String(len(counted_space)))
  
  var all_perms = generate_all_permutations()
  var discovered_sudokus = Dict[String, Sudoku4x4]()
  var canonical_buckets = Dict[String, List[Sudoku4x4]]()
  
  for sudoku in counted_space.values():
    var sudoku_hash = String(sudoku)
    if sudoku_hash in discovered_sudokus: 
      continue

    var bucket = List[Sudoku4x4]()
    bucket.append(sudoku)
    discovered_sudokus[String(sudoku)] = sudoku
    
    # Try all 24 permutations (skip first one which is identity)
    for i in range(1, len(all_perms)):
      var relabelled = relabel(sudoku, all_perms[i])
      var relabelled_hash = String(relabelled)
      if relabelled_hash not in discovered_sudokus:
        discovered_sudokus[relabelled_hash] = relabelled
        bucket.append(relabelled)
    
    if len(bucket) > 0:
      canonical_buckets[sudoku_hash] = bucket
  
  return canonical_buckets
