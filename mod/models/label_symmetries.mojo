from .sudoku import Sudoku4x4

# -------------------------------------------------------------------
# relabel — apply a digit permutation to a 4×4 Sudoku
# -------------------------------------------------------------------
# Effect:
#   For each non-zero cell value d ∈ {1,2,3,4}, replace it with perm[d-1].
#   Zeros (empties) remain unchanged.
#
# Contract:
#   - perm must be a 4-element permutation of [1,2,3,4].
#   - String/row-major encoding downstream assumes relabeling is consistent.
# -------------------------------------------------------------------
fn relabel(grid: Sudoku4x4, perm: List[Int]) -> Sudoku4x4:
    # Work on a local copy so the input grid isn't mutated.
    var copy = grid

    for row in range(4):
        for col in range(4):
            var old_val = grid.get(row, col)
            if old_val > 0:
                # Map 1→perm[0], 2→perm[1], 3→perm[2], 4→perm[3]
                copy.set(row, col, perm[old_val - 1])

    return copy


# -------------------------------------------------------------------
# generate_all_permutations — all 4! = 24 digit relabelings
# -------------------------------------------------------------------
# Output:
#   List of 24 arrays p, each a permutation of [1,2,3,4].
#   Interpretation: digit d → p[d-1].
# -------------------------------------------------------------------
fn generate_all_permutations() raises -> List[List[Int]]:
    var perms = List[List[Int]]()

    for i in range(1, 5):
        for j in range(1, 5):
            if j == i: continue
            for k in range(1, 5):
                if k == i or k == j: continue
                for h in range(1, 5):
                    if h == i or h == j or h == k: continue
                    perms.append(List[Int](i, j, k, h))  # may raise

    return perms
