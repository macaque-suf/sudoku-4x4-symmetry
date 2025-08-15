from .sudoku import Sudoku4x4
from .label_symmetries import relabel
from .geo_symmetries import GeoXform, describe_geo, apply_geo

# -------------------------------------------------------------------
# CanonTrace — record one candidate in the canonical race
# -------------------------------------------------------------------
struct CanonTrace(Copyable & Movable):
    var geo_label: String   # human-readable label for the geometry transform
    var perm_label: String  # label for the digit permutation
    var encoded: String     # string representation of the transformed Sudoku
    var is_best: Bool       # marks the lexicographic winner

    fn __init__(out self,
                geo_label: String,
                perm_label: String,
                encoded: String,
                is_best: Bool):
        self.geo_label = geo_label
        self.perm_label = perm_label
        self.encoded = encoded
        self.is_best = is_best

# Collect every image and mark the canonical minimum
fn canonical_full_with_trace(g: Sudoku4x4,
                             geos: List[GeoXform],
                             perms: List[List[Int]]) -> (String, List[CanonTrace]):
    var traces = List[CanonTrace]()
    var best = "9999999999999999"
    var best_i = -1

    var i = 0
    for T in geos:
        var geo_lbl = describe_geo(T)
        var gt = apply_geo(g, T)
        for p in perms:
            var perm_lbl = "perm(" + String(p[0]) + String(p[1]) + String(p[2]) + String(p[3]) + ")"
            var r = relabel(gt, p)
            var s = String(r)
            traces.append(CanonTrace(geo_lbl, perm_lbl, s, False))
            if s < best:
                best = s
                best_i = i
            i += 1
    if best_i >= 0:
        traces[best_i].is_best = True
    return (best, traces)
