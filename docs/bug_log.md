# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)
## Bug Log & Debugging History

This document tracks all functional anomalies, edge-case bugs, and architectural flaws discovered during Verilog RTL development and ModelSim simulation, along with their root causes and corrective actions.

---

### Bug Summary Table

| Bug ID | Task Discovered | Description / Root Cause | Corrective Action / RTL Fix | Status |
| :--- | :--- | :--- | :--- | :--- |
| **BUG-01** | Task 2 (Timer) | The generic timer failed to assert the `done` signal when configured with `count_target == 0`, causing the FSM to stall indefinitely in zero-duration safety states. | Updated `generic_timer.v` combinatorial logic to immediately assert `done = 1` on the next clock cycle when `start` is high and `count_target == 0`. | **Resolved** |
| **BUG-02** | Task 3 (Integration) | Using a fixed-priority scheme in the pedestrian arbiter caused Junction B pedestrian requests to suffer permanent starvation when continuous simultaneous requests arrived. | Replaced the fixed priority logic in `ped_arbiter.v` with a rotating round-robin state register (`last_served`), ensuring alternating priority grants. | **Resolved** |
| **BUG-03** | Task 4 (Adaptive Timing)| Fluctuating `traffic_density` values updated mid-phase caused the active timer target to jump, resulting in corrupted green light durations and waveform glitches. | Implemented an input-latching register in `junction_controller.v` that samples `traffic_density` exclusively at the exact transition into a green phase. | **Resolved** |

---

### Detailed Bug Analysis & Engineering Notes

#### BUG-01: Zero-Target Timer Lockup
- **Symptom:** During initial timer module testing, setting `count_target = 0` resulted in the FSM freezing because `done` never went high.
- **Root Cause:** The countdown comparator only checked when the internal decrement register reached zero from a positive number, missing the edge case where the target itself starts at zero.
- **Fix:** Added an explicit conditional check inside `generic_timer.v`: `assign done = (count_target == 0 && start) ? 1'b1 : (internal_count == 0);`.

#### BUG-02: Pedestrian Starvation under Heavy Load
- **Symptom:** In integration testing under simultaneous multi-cycle requests, Junction A received all crosswalk grants while Junction B requests timed out.
- **Root Cause:** A hardcoded priority check (`if (req_a) grant_a = 1; else grant_b = 1;`) always favored Junction A.
- **Fix:** Introduced a `last_served` toggle register inside `ped_arbiter.v`. When both requests are high, the arbiter grants the opposite junction of whoever was last served, completely eliminating starvation.

#### BUG-03: Mid-Phase Density Jitter
- **Symptom:** Green light countdown timers abruptly shortened or lengthened halfway through a phase when testbench traffic density stimuli changed.
- **Root Cause:** Continuous combinatorial evaluation of `traffic_density` fed directly into the active timer reload register.
- **Fix:** Locked the density value into a local register (`current_density`) at the exact clock edge the FSM enters `S_NS_GREEN` or `S_EW_GREEN`, holding it steady for the remainder of that phase.
