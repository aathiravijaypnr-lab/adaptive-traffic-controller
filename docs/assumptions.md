# AMTGC — System Assumptions and Design Boundaries

## Clock and reset

- The design uses one `clk` clock domain.
- `rst_n` is active low. `junction_controller`, `generic_timer`, and `green_wave_sync` use asynchronous assertion of reset (`posedge clk or negedge rst_n`). `ped_arbiter` uses synchronous reset (`posedge clk`). Therefore reset behavior is **not identical in every module**.
- The design is a simulation-oriented RTL controller, not a certified physical traffic system.

## Default configuration

| Parameter | Junction A | Junction B | Meaning |
| :--- | ---: | ---: | :--- |
| `MIN_GREEN_TIME` | 5 | 5 | Minimum green count |
| `MAX_GREEN_TIME` | 10 | 10 | Maximum green count |
| `GREEN_EXTENSION` | 1 | 1 | Added count per density level |
| `YELLOW_TIME` | 3 | 3 | Yellow count |
| `RED_TIME` | 8 | 8 | All-red count |
| `PEDESTRIAN_TIME` | 6 | 6 | Pedestrian count |
| `IS_JUNCTION_B` | 0 | 1 | Enables Junction B synchronization behavior |
| Timer `COUNTER_WIDTH` | 32 | 32 | Timer width as instantiated in `amtgc_top` |

The top-level `SYNC_OFFSET_TIME` default is **4**. Parameter values represent clock-count targets, not physical seconds.

## Traffic density and timing

- `density_a[2:0]` and `density_b[2:0]` independently represent unsigned density levels 0–7.
- Each controller computes `MIN_GREEN_TIME + traffic_density * GREEN_EXTENSION`, clamped to `[MIN_GREEN_TIME, MAX_GREEN_TIME]`. With defaults, the targets are **5, 6, 7, 8, 9, 10, 10, 10**.
- The computed green target is stored in `sampled_green_time` at green-phase entry, avoiding mid-phase timer-target changes.
- The programmed count target is not a guarantee of a particular measured output pulse length in every synchronized scenario. The integrated log reports a two-cycle Junction B NS-green observation in one test; see `sim/simulation_run.log`.

## Coordination and safety assumptions

- `green_wave_sync` detects Junction A entering NS green and emits a delayed pulse; Junction B also observes its own safety/state conditions before entering NS green.
- The shared `ped_arbiter` receives requests and readiness inputs and uses the `turn` register for round-robin priority when both are eligible. The integrated fairness test reports 50 grants per junction over 100 arbitration cycles; this is evidence for the tested scenario, not a formal proof for all possible stimuli.
- `emergency_override` masks traffic/pedestrian outputs and gates pedestrian requests and the synchronization trigger at the top level. The controllers enter the emergency state on a clock edge and resume through all-red handling.
- There are no dedicated red output pins. All-red means vehicle green/yellow and pedestrian walk indications are inactive.
