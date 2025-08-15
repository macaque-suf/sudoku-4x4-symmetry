from .models.sudoku import Sudoku4x4
from .models.geo_symmetries import GeoXform, all_geo, apply_geo
from .models.label_symmetries import relabel, generate_all_permutations


# -------------------------------------------------------------------
# 1) Generate ALL 288 solved 4x4 sudokus (backtracking)
# -------------------------------------------------------------------
fn backtrack(mut grid: Sudoku4x4, row: Int, col: Int) raises -> Dict[String, Sudoku4x4]:
    """
    Enumerates every 4×4 Sudoku completion that’s consistent with the current `grid`.

    Parameters
    ----------
    grid : Sudoku4x4 (mutable)
        The board we’re filling. Convention: 0 means "empty".
    row, col : Int
        Zero-based coordinates of the cell we’re about to assign.

    Returns
    -------
    Dict[String, Sudoku4x4]
        A dictionary mapping a canonical string (String(grid)) to the completed board.
        Using a dict guarantees uniqueness if `String(grid)` is canonical.

    How it works (in one breath)
    ----------------------------
    - Try candidates 1..4 in the current cell.
    - After each tentative write, validate the *partial* board
      (no duplicates so far in row/col/2×2 box; zeros are ignored).
    - If still valid:
        - Move to the next cell in row-major order and recurse.
        - If we just filled the last cell (row=3, col=3), record a solution.
    - Undo the write (set back to 0) before returning to explore the next candidate.

    Complexity intuition
    --------------------
    Worst case is ~4^16 branches, but partial-validation prunes massively.
    For 4×4, this explores fast and yields the well-known 288 completions.
    """

    # Collect solutions from this subtree.
    var results_dict = Dict[String, Sudoku4x4]()

    # Try all possible symbols for a 4×4 Sudoku (1..4).
    for candidate in range(1, 5):
        # 1) Place a tentative value in the current cell.
        grid.set(row, col, candidate)

        # 2) Check the *partial* constraints: rows, columns, and 2×2 boxes may not
        #    contain duplicates among the non-zero entries.
        if grid.is_valid(ignore_incomplete = True):
            # 3) Decide whether to recurse or to record a full solution.
            var solutions: Dict[String, Sudoku4x4]

            # If we are NOT at the last cell (3,3), go fill the next cell.
            if row != 3 or col != 3:
              # Compute the linear index of the *next* cell in row-major order,
              # then convert it back to (row, col).
              #   current linear index  = row * 4 + col
              #   next linear index     = current + 1
              var index = (row * 4 + col) + 1

              # Recurse on the next cell.
              solutions = backtrack(grid, index // 4, index % 4)  # raises

            else:
              # Base case: we just set (3,3) and the grid is valid — so it's a solution.

              # NOTE:
              # Sudoku4x4 is defined as a struct with the Copyable trait, so it’s a value type.
              # That means any time we assign `grid` into the solutions dictionary, we’re storing
              # an independent copy of its data. The original `grid` can be safely mutated later
              # during backtracking without affecting the stored solution.
              # (If this were a reference type, we’d need to explicitly copy it here.)
              var key = String(grid)
              solutions = { key: grid }   # replace `grid` with `grid.copy()` if needed

            # 4) Merge all solutions found in this branch.
            #    (May raise if capacity issues — that’s why the function is `raises`.)
            results_dict.update(solutions)

        # 5) Undo the tentative write so the next candidate starts from a clean slate.
        #    This is the “backtrack” in backtracking.
        grid.set(row, col, 0)

    # Return everything found from this cell onward.
    return results_dict


# -------------------------------------------------------------------
# 2) RELABEL-ONLY canonicalization → pick 12 representatives
# -------------------------------------------------------------------
fn canonical_relabel_only(g: Sudoku4x4, perms: List[List[Int]]) -> (String, Sudoku4x4):
    """
    Given a completed Sudoku4x4 board `g`, find its **canonical representative**
    under digit-relabeling symmetry only.

    Context:
    --------
    - In Sudoku, we can permute the symbols (1↔2, 3↔4, etc.) without breaking validity.
    - All boards related by these relabelings belong to the same *equivalence class*.
    - By picking the "smallest" string representation among them, we define
      a unique representative for the class.
    - This function ignores geometric symmetries (rotations, reflections, box swaps) —
      it's **relabel-only** canonicalization.

    Parameters:
    -----------
    g : Sudoku4x4
        The solved grid we want to canonicalize.
    perms : List[List[Int]]
        A precomputed list of symbol permutations to try.
        Each permutation is a mapping from old digit → new digit.
        Example for 4×4: [1,2,3,4], [1,3,2,4], [2,1,3,4], etc.

    Returns:
    --------
    (best_key, best_grid) : (String, Sudoku4x4)
        best_key  — the lexicographically smallest string form among all relabelings.
        best_grid — the corresponding Sudoku4x4 grid.

    Algorithm in words:
    -------------------
    1. Start with a "sentinel" string that's larger than any valid board representation.
    2. For each permutation in `perms`:
        - Apply it to the board using `relabel()`.
        - Convert the relabeled board to a compact string (`String(r)`).
        - If this string is lexicographically smaller than the current best:
            → Update the best string and remember its grid.
    3. Return the best string and the best grid.
    """

    # Start with a sentinel key — all '9's — guaranteed to be larger than any real board key
    # since valid 4×4 boards only use digits '1' to '4' in their string form.
    var best = "9999999999999999"  # 16 chars sentinel (one for each cell)

    # Track the grid corresponding to the current best key.
    var best_grid = g

    # Try every digit permutation.
    for p in perms:
        # Relabel the grid according to this permutation.
        var r = relabel(g, p)

        # Get the string representation of the relabeled grid.
        var s = String(r)

        # If this permutation produces a lexicographically smaller key, take it.
        if s < best:
            best = s
            best_grid = r

    # Return both the minimal key and its corresponding grid.
    return (best, best_grid)


# -------------------------------------------------------------------
# 3) FULL canonicalization (geometry × relabeling)
# -------------------------------------------------------------------
fn canonical_full(
    g: Sudoku4x4,
    geos: List[GeoXform],       # All geometric symmetries to test
    perms: List[List[Int]]      # All digit relabelings to test
) -> String:
    """
    Returns the *canonical* representative of a Sudoku grid under both:

      1. **Geometric transformations** (`GeoXform`):
         - Row swaps within each band (swap_r_band0, swap_r_band1)
         - Band swaps (swap_bands) — exchange top and bottom halves
         - Column swaps within each stack (swap_c_stack0, swap_c_stack1)
         - Stack swaps (swap_stacks) — exchange left and right halves
         - Optional transpose (transpose_flag) — swap rows/columns across the main diagonal

         These are exactly the “legal” symmetry operations that preserve Sudoku validity.

      2. **Digit relabelings**:
         - Every permutation `p` of {1, 2, 3, 4} maps digit d → p[d−1]
           (leaving empties as is, if present).
         - Example: [2,3,4,1] means “replace 1→2, 2→3, 3→4, 4→1”.

    How it works:
    -------------
    - For each geometric transform T in `geos`:
        - Apply T to `g` using `apply_geo()`, which internally:
            * Swaps rows/columns within bands/stacks if the relevant flags are set
            * Swaps entire bands/stacks if those flags are set
            * Optionally transposes the grid if `transpose_flag` is true
        - For each digit permutation p in `perms`:
            * Apply `relabel()` to rename all digits according to p
            * Convert to a 16-character string in fixed order (e.g. row-major)
            * Keep track of the lexicographically smallest string seen so far

    Why lexicographic minimum?
    --------------------------
    This creates a unique “canonical form” string for each symmetry-equivalence class.
    Any two boards that differ only by allowed geometry + digit relabeling will
    reduce to the same string.

    Returns:
    --------
    The lexicographically smallest string among all transformed+relabelled versions
    of the input `g`. This can be used as a hash key to group equivalent Sudokus.
    """

    var best = "9999999999999999"  # Sentinel larger than any valid Sudoku string

    for T in geos:
        # Apply the current geometric transform
        var gt = apply_geo(g, T)

        for p in perms:
            # Apply digit relabeling
            var r = relabel(gt, p)

            # Encode to string (row-major, no spaces)
            var s = String(r)

            # Keep the smallest string seen so far 
            if s < best: 
              best = s

    return best


# -------------------------------------------------------------------
# 4) Collapse the 12 relabel-reps under FULL symmetry → 2 buckets
# -------------------------------------------------------------------
fn collapse_from_reps(reps: List[Sudoku4x4]) raises -> Dict[String, List[Sudoku4x4]]:
    """
    Groups a small set of representative 4×4 Sudokus into equivalence classes
    under the *full* symmetry group = (geometry × digit relabeling).

    Input
    -----
    reps : List[Sudoku4x4]
        Your 12 "relabel representatives" (already deduped by digit permutations only).

    Output
    ------
    Dict[String, List[Sudoku4x4]]
        A map from canonical key (lexicographic min string) → all reps in that class.
        In this 4×4 story, the 12 reps collapse into exactly 2 buckets.
    """
    # Geometric transforms: all combinations of row/col swaps within bands/stacks,
    # whole band/stack swaps, and optional transpose.
    # (7 boolean flags → up to 128 transforms; some may coincide but that's fine.)
    var geos = all_geo()                    # 128 (may raise due to list appends)

    # All 4! = 24 digit permutations (1..4). See below for implementation.
    var perms = generate_all_permutations() # 24 (may raise)

    var buckets = Dict[String, List[Sudoku4x4]]()

    var idx = 0
    for g in reps:
        idx += 1

        # Canonical key under FULL symmetry (geometry × relabeling).
        var key = canonical_full(g, geos, perms)

        # Create the bucket if it doesn't exist yet.
        if not (key in buckets):
            buckets[key] = List[Sudoku4x4]()     # may raise (alloc/append)

        # Article-friendly trace: shows which rep landed in which canonical class.
        print("rep#", String(idx), " → FULL_CANON=", key)

        # Add this representative to its equivalence class.
        buckets[key].append(g)                   # may raise

    return buckets


# -------------------------------------------------------------------
# 5) Full collapse starting from ALL 288
#    Returns: buckets under FULL symmetry (keys are canonical strings).
# -------------------------------------------------------------------
fn count() raises -> Dict[String, List[Sudoku4x4]]:
    """
    Pipeline:
      1) Enumerate the entire 4×4 Sudoku solution space via backtracking (should be 288).
      2) Precompute all allowed board geometries and digit permutations.
      3) For each solved grid, compute its FULL canonical key (geometry × relabel).
      4) Group identical keys into "buckets" — each bucket is one symmetry class.

    Output:
      Dict[String, List[Sudoku4x4]]
        key   = canonical string (lexicographic min over all transforms)
        value = all solved grids that collapse to this canonical representative
    """

    # 1) Generate all completions from an empty board.
    #    NOTE: backtrack returns { String(grid) -> Sudoku4x4 } to ensure uniqueness.
    var blank_grid = Sudoku4x4()
    var counted_space = backtrack(blank_grid, 0, 0)   # may raise

    # Friendly trace: should print "288" for a standard 4×4 rule set.
    print("counted_space: ", String(len(counted_space)))

    # 2) Precompute symmetry sets once (saves work in the inner loop).
    var geos = all_geo()                    # up to 128 GeoXform combinations
    var all_perms = generate_all_permutations()  # 24 digit permutations

    # 3) Accumulate buckets keyed by FULL canonical string.
    var buckets = Dict[String, List[Sudoku4x4]]()

    # Iterate over every solved grid in the counted space.
    for sudoku in counted_space.values():
        # Compute canonical representative under (geometry × relabeling).
        var key = canonical_full(sudoku, geos, all_perms)

        # Create a new bucket if we haven't seen this canonical key yet.
        if not (key in buckets):
            buckets[key] = List[Sudoku4x4]()  # may raise

        # Add this concrete solution to its equivalence class.
        buckets[key].append(sudoku)           # may raise

    # 4) Each dict entry is one symmetry class of 4×4 solutions.
    return buckets

fn relabel_representatives() raises -> List[Sudoku4x4]:
    """
    Compute the 12 canonical representatives under relabeling symmetry only.
    """
    var blank = Sudoku4x4()
    var all_solutions = backtrack(blank, 0, 0)            # 288
    var perms = generate_all_permutations()                # 24

    var seen = Dict[String, Bool]()
    var reps = List[Sudoku4x4]()

    for g in all_solutions.values():
        var (key, best_grid) = canonical_relabel_only(g, perms)
        if not (key in seen):
            seen[key] = True
            reps.append(best_grid)                         # may raise

    return reps    # should be 12

