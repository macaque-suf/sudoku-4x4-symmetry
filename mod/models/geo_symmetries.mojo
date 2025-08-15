from .sudoku import Sudoku4x4

# -------------------------------------------------------------------
# GeoXform — Encodes a single geometric symmetry operation on a 4×4 Sudoku
# -------------------------------------------------------------------
# Each flag represents a legal transformation that preserves Sudoku validity.
# They can be combined to produce the full 2^7 = 128-element geometry group.
#
# Row and column terminology:
#   - A "band" = two adjacent rows treated as a unit (rows 0–1 and rows 2–3).
#   - A "stack" = two adjacent columns treated as a unit (cols 0–1 and cols 2–3).
#
# In a 4×4, there are exactly 2 bands and 2 stacks.
# -------------------------------------------------------------------
struct GeoXform(Copyable & Movable):
  # ---- Row transformations ----
    var swap_r_band0: Bool   # Swap the two rows within band 0  → swap row 0 ↔ row 1
    var swap_r_band1: Bool   # Swap the two rows within band 1  → swap row 2 ↔ row 3
    var swap_bands:   Bool   # Swap the two bands as units       → swap rows (0,1) ↔ (2,3)

    # ---- Column transformations ----
    var swap_c_stack0: Bool  # Swap the two columns within stack 0  → swap col 0 ↔ col 1
    var swap_c_stack1: Bool  # Swap the two columns within stack 1  → swap col 2 ↔ col 3
    var swap_stacks:   Bool  # Swap the two stacks as units         → swap cols (0,1) ↔ (2,3)

    # ---- Transpose ----
    var transpose_flag: Bool # Transpose the grid across the main diagonal (row ↔ col)

    # Constructor: defaults to "no transformation" (all flags False).
    fn __init__(out self,
                swap_r_band0: Bool = False,
                swap_r_band1: Bool = False,
                swap_bands:   Bool = False,
                swap_c_stack0: Bool = False,
                swap_c_stack1: Bool = False,
                swap_stacks:   Bool = False,
                transpose_flag: Bool = False):
        self.swap_r_band0 = swap_r_band0
        self.swap_r_band1 = swap_r_band1
        self.swap_bands   = swap_bands
        self.swap_c_stack0 = swap_c_stack0
        self.swap_c_stack1 = swap_c_stack1
        self.swap_stacks   = swap_stacks
        self.transpose_flag = transpose_flag


# -------------------------------------------------------------------
# apply_rows — row-level symmetries for a 4×4 grid
#   b0    : swap rows 0 ↔ 1   (within top band)
#   b1    : swap rows 2 ↔ 3   (within bottom band)
#   bands : swap bands (0–1) ↔ (2–3) as units
# -------------------------------------------------------------------
fn apply_rows(mut g: Sudoku4x4, b0: Bool, b1: Bool, bands: Bool) -> Sudoku4x4:
    # Work on a local copy so the caller's grid remains unchanged by this function.
    # (Whether this is a value copy or reference depends on Sudoku4x4 semantics.)
    var out = g

    # If b0 is set, swap the two rows in the *top* band: row 0 ↔ row 1.
    # We swap cell-by-cell across all 4 columns.
    if b0:
        for c in range(4):
            var a = out.get(0, c); var b = out.get(1, c)
            out.set(0, c, b);      out.set(1, c, a)

    # If b1 is set, swap the two rows in the *bottom* band: row 2 ↔ row 3.
    if b1:
        for c in range(4):
            var a = out.get(2, c); var b = out.get(3, c)
            out.set(2, c, b);      out.set(3, c, a)

    # If bands is set, swap the *bands as units*: (rows 0,1) ↔ (rows 2,3).
    # This preserves the internal order of each band (after any above swaps).
    if bands:
        for c in range(4):
            # Swap row 0 with row 2 at column c
            var a = out.get(0, c); var b = out.get(2, c)
            out.set(0, c, b);      out.set(2, c, a)

            # Swap row 1 with row 3 at column c
            var a2 = out.get(1, c); var b2 = out.get(3, c)
            out.set(1, c, b2);      out.set(3, c, a2)

    return out


# -------------------------------------------------------------------
# apply_cols — column-level symmetries for a 4×4 grid
#   s0     : swap columns 0 ↔ 1   (within left stack)
#   s1     : swap columns 2 ↔ 3   (within right stack)
#   stacks : swap stacks (0–1) ↔ (2–3) as units
# -------------------------------------------------------------------
fn apply_cols(mut g: Sudoku4x4, s0: Bool, s1: Bool, stacks: Bool) -> Sudoku4x4:
    # Work on a local copy (value vs reference depends on Sudoku4x4 semantics).
    var out = g

    # If s0 is set, swap the two columns in the *left* stack: col 0 ↔ col 1.
    # We swap cell-by-cell down all 4 rows.
    if s0:
        for r in range(4):
            var a = out.get(r, 0); var b = out.get(r, 1)
            out.set(r, 0, b);      out.set(r, 1, a)

    # If s1 is set, swap the two columns in the *right* stack: col 2 ↔ col 3.
    if s1:
        for r in range(4):
            var a = out.get(r, 2); var b = out.get(r, 3)
            out.set(r, 2, b);      out.set(r, 3, a)

    # If stacks is set, swap the *stacks as units*: (cols 0,1) ↔ (cols 2,3).
    # Internal order of each stack is preserved (after any above swaps).
    if stacks:
        for r in range(4):
            # Swap col 0 with col 2 in row r
            var a = out.get(r, 0); var b = out.get(r, 2)
            out.set(r, 0, b);      out.set(r, 2, a)

            # Swap col 1 with col 3 in row r
            var a2 = out.get(r, 1); var b2 = out.get(r, 3)
            out.set(r, 1, b2);      out.set(r, 3, a2)

    return out


# -------------------------------------------------------------------
# transpose_grid — transpose a 4×4 Sudoku across its main diagonal
# -------------------------------------------------------------------
# Effect:
#   Turns rows into columns and columns into rows:
#       new[r][c] = old[c][r]
#   This is the standard matrix transpose, reflecting the grid along
#   the main diagonal (top-left → bottom-right).
#
# Why it’s valid for Sudoku:
#   Row constraints ↔ Column constraints.
#   Because the puzzle rules are symmetric with respect to rows/columns,
#   transposing preserves validity.
# -------------------------------------------------------------------
fn transpose_grid(g: Sudoku4x4) -> Sudoku4x4:
    # Work on a local copy of the grid.
    var out = g

    # Only swap cells above the diagonal (c > r).
    # This avoids swapping a pair twice or touching the diagonal cells at all.
    for r in range(4):
        for c in range(r + 1, 4):
            # Swap (r, c) ↔ (c, r)
            var a = out.get(r, c)
            var b = out.get(c, r)
            out.set(r, c, b)
            out.set(c, r, a)

    return out


# -------------------------------------------------------------------
# apply_geo — apply a complete geometric transformation to a 4×4 Sudoku
# -------------------------------------------------------------------
# Parameters:
#   g : Sudoku4x4   → the grid to transform
#   t : GeoXform    → the set of row/column/transpose flags to apply
#
# This function executes a GeoXform in three stages:
#   1. Row swaps (within bands, between bands)
#   2. Column swaps (within stacks, between stacks)
#   3. Optional transpose
#
# The order here is fixed and consistent with how we enumerate `all_geo()`.
# Each operation preserves Sudoku validity — together they form the 2^7 = 128
# possible geometric symmetries for a 4×4 grid.
# -------------------------------------------------------------------
fn apply_geo(g: Sudoku4x4, t: GeoXform) -> Sudoku4x4:
    # Make a mutable local copy since `apply_rows`/`apply_cols` expect `mut` parameters.
    var h = g

    # Stage 1: Apply row-level symmetries
    h = apply_rows(h, t.swap_r_band0, t.swap_r_band1, t.swap_bands)

    # Stage 2: Apply column-level symmetries
    h = apply_cols(h, t.swap_c_stack0, t.swap_c_stack1, t.swap_stacks)

    # Stage 3: Apply transpose if requested
    if t.transpose_flag:
        h = transpose_grid(h)

    # Return the fully transformed grid
    return h


# Produce intermediate representations for a single GeoXform:
#   start → after rows → after cols → after (optional) transpose
fn apply_geo_with_trace(g: Sudoku4x4, t: GeoXform) -> List[(String, Sudoku4x4, String)]:
    # Each tuple: (stage_label, grid, string_encoding)
    var out = List[(String, Sudoku4x4, String)]()

    var h = g
    out.append(("start", h, String(h)))

    # Stage 1: rows
    h = apply_rows(h, t.swap_r_band0, t.swap_r_band1, t.swap_bands)
    out.append(("after_rows", h, String(h)))

    # Stage 2: cols
    h = apply_cols(h, t.swap_c_stack0, t.swap_c_stack1, t.swap_stacks)
    out.append(("after_cols", h, String(h)))

    # Stage 3: transpose (optional)
    if t.transpose_flag:
        h = transpose_grid(h)
        out.append(("after_transpose", h, String(h)))

    return out


# For a given grid, emit every permutation’s result, with a compact perm label.
fn relabel_with_trace(g: Sudoku4x4, perms: List[List[Int]]) -> List[(String, Sudoku4x4, String)]:
    var out = List[(String, Sudoku4x4, String)]()
    for p in perms:
        var lbl = "perm(" + String(p[0]) + String(p[1]) + String(p[2]) + String(p[3]) + ")"
        var r = relabel(g, p)
        out.append((lbl, r, String(r)))
    return out


# -------------------------------------------------------------------
# all_geo — enumerate all 2^7 geometric transformations for a 4×4 Sudoku
# -------------------------------------------------------------------
# Output:
#   A list of GeoXform objects, one for each possible combination of:
#       - swap_r_band0   (bit 0)  : row 0 ↔ row 1
#       - swap_r_band1   (bit 1)  : row 2 ↔ row 3
#       - swap_bands     (bit 2)  : (rows 0,1) ↔ (rows 2,3)
#       - swap_c_stack0  (bit 3)  : col 0 ↔ col 1
#       - swap_c_stack1  (bit 4)  : col 2 ↔ col 3
#       - swap_stacks    (bit 5)  : (cols 0,1) ↔ (cols 2,3)
#       - transpose_flag (bit 6)  : transpose across main diagonal
#
# Why 128?
#   Each flag is Boolean, so there are 2^7 = 128 possible on/off patterns.
#   Some combinations produce the same final transform (group structure),
#   but generating all is simpler and still very fast.
# -------------------------------------------------------------------
fn all_geo() -> List[GeoXform]:
    var xs = List[GeoXform]()

    # mask iterates over all binary patterns from 0b0000000 to 0b1111111
    for mask in range(128):  # 0..127
        var t = GeoXform(
            swap_r_band0    = (mask & 1)   != 0,  # bit 0
            swap_r_band1    = (mask & 2)   != 0,  # bit 1
            swap_bands      = (mask & 4)   != 0,  # bit 2
            swap_c_stack0   = (mask & 8)   != 0,  # bit 3
            swap_c_stack1   = (mask & 16)  != 0,  # bit 4
            swap_stacks     = (mask & 32)  != 0,  # bit 5
            transpose_flag  = (mask & 64)  != 0   # bit 6
        )
        xs.append(t)

    return xs


# Turn a GeoXform into a short, readable label for captions/logs
fn describe_geo(t: GeoXform) -> String:
    var parts = List[String]()
    if t.swap_r_band0: parts.append("r01")     # rows 0↔1
    if t.swap_r_band1: parts.append("r23")     # rows 2↔3
    if t.swap_bands:   parts.append("Rswap")   # bands (0–1)↔(2–3)
    if t.swap_c_stack0: parts.append("c01")    # cols 0↔1
    if t.swap_c_stack1: parts.append("c23")    # cols 2↔3
    if t.swap_stacks:   parts.append("Cswap")  # stacks (0–1)↔(2–3)
    if t.transpose_flag: parts.append("T")     # transpose
    if len(parts) == 0:
        return "identity"
    # Join with '+' (compact for figure captions)
    var s = parts[0]
    for i in range(1, len(parts)):
        s += "+" + parts[i]
    return s
