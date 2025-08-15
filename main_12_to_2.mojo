from mod.count_occurance import relabel_representatives, collapse_from_reps
from mod.models.label_symmetries import generate_all_permutations
from mod.models.geo_symmetries import all_geo
from mod.models.canon_trace import canonical_full_with_trace   # and CanonTrace/describe_geo if needed

fn main() raises:
    # ------------------------------------------------------------
    # Part A — What readers already know from Part 1 (12 reps)
    # ------------------------------------------------------------
    var reps = relabel_representatives()
    print("Part-1 representatives (relabel-only): ", String(len(reps)))  # expect 12

    # ------------------------------------------------------------
    # Part B — Collapse those 12 under FULL symmetry (→ 2 buckets)
    # ------------------------------------------------------------
    var buckets = collapse_from_reps(reps)
    print("Full-symmetry buckets: ", String(len(buckets)))               # expect 2

    # Article-friendly summary
    for entry in buckets.items():
        var k = entry.key
        var vs = entry.value
        print(" - bucket key=", k, " size(reps)=", String(len(vs)))

    # ------------------------------------------------------------
    # Part C — Demo: show intermediate images for one representative
    #           (geometry × relabel) and highlight the canonical win
    # ------------------------------------------------------------
    if len(reps) > 0:
        var geos = all_geo()                           # 128
        var perms = generate_all_permutations()        # 24

        # Pick the first rep for the demo (or choose any index you like)
        var demo_grid = reps[0]
        var (best_key, traces) = canonical_full_with_trace(demo_grid, geos, perms)

        print("\nCanonical race demo on rep#1")
        print("BEST =", best_key)

        # Show the first few candidates plus the winner
        var shown = 0
        for t in traces:
            if t.is_best or shown < 8:
                print(t.geo_label, " × ", t.perm_label, " → ", t.encoded, "  <-- WINNER" if t.is_best else "")
                shown += 1

