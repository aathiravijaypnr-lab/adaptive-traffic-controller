# AMTGC — Debugging and Verification Notes

This document records implementation concerns and the final mechanisms that address them. The final repository alone does **not** establish the exact history of earlier bugs or when each was discovered; therefore these entries should not be read as verified claims about earlier failing revisions.

| ID | Engineering concern | Final RTL handling | Evidence |
| :--- | :--- | :--- | :--- |
| DBG-01 | Zero-target timer and restart edge cases | `generic_timer.v` uses `zero_done_flag`, `previous_target`, and registered `done` | Timer RTL and standalone timer testbench |
| DBG-02 | Competing pedestrian requests | `ped_arbiter.v` uses the `turn` register, readiness checks, and mutually exclusive registered grants | Integrated fairness test: 50 A / 50 B, 0 alternation errors |
| DBG-03 | Density changes during an active green phase | `junction_controller.v` stores the computed duration in `sampled_green_time` on green entry | Integrated adaptive timing and mid-phase stability tests |
| DBG-04 | Emergency and synchronization interaction | Top-level masks `sync_trigger_raw` using `~emergency_override`; controllers gate outputs and enter `ST_EMERGENCY` | Integrated emergency tests and waveforms |

## Technical details

### Timer behavior
`done` is a **registered pulse**, not a combinational `assign`. For a zero target, the timer generates one pulse per activation using `zero_done_flag`. Deasserting `start` clears its counting state; a changed target also restarts the count.

### Pedestrian arbitration
The implementation uses `turn`, **not** `last_served`. Grants depend on `req_a`/`req_b` and `ready_a`/`ready_b`; `ped_walk_a` and `ped_walk_b` are produced by the junction controllers, not by the arbiter.

### Adaptive duration
The implementation stores the **computed green duration** in `sampled_green_time`, rather than storing the raw density in a `current_density` register.

## Verification status
The committed `sim/simulation_run.log` reports **39 PASS / 0 FAIL**, including a **1,000-cycle randomized run with zero new invariant violations**. This log documents the observed tests; it is not exhaustive formal verification.
