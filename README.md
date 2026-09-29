# adaptive-traffic-controller - System Architecture Plan

## 1. Top-Level System Architecture

The system is designed as a modular, single-clock digital system that controls two 4-way traffic junctions (Junction A and Junction B) with green-wave coordination, a shared pedestrian arbiter, and a central emergency override controller.

+---------------------------------------------------------------------------------------+
|                                ADAPTIVE_TRAFFIC_TOP                                   |
|                                                                                       |
|            (1) Green-Wave Synchronization                                             |
|         +-------------------------------------------------------------+               |
|         |                     junc_a_ns_green                         |               |
|  +------v-----+  (A enters    +--------------------+  sync_trigger_b  | +-----------+ |
|  | Junction A |   NS_GREEN)   |  GREEN_WAVE_SYNC   |  (1-cycle pulse) | | Junction B| |
|  | Traffic    |-------------->|                    |------------------->| Traffic   | |
|  | FSM Logic  |               | GREEN_WAVE_DELAY   |                  | | FSM Logic | |
|  +------+-----+               +--------------------+                  +-----+-----+ |
|         |                                                                   |         |
|         |          (2) Shared Pedestrian Requests & Grants                  |         |
|         +-------------------------------------------------------------------+         |
|  req_a, junction_a_state                                 req_b, junction_b_state      |
|    |      grant_a                                           |      grant_b            |
|    v         ^                                              v         ^               |
| +--+---------+----------------------------------------------+---------+-------------+ |
| |                                                                                   | |
| |                             PEDESTRIAN_ARBITER                                    | |
| |                           (Round-Robin Policy)                                    | |
| +------------------------------------+----------------------------------------------+ |
|                                      ^                                                |
|            (3) Global Emergency      | emergency_hold                                 |
|            Override Control          | (Forces ALL_RED within 2 cycles)              |
|   +----------------------------------+------------------------+                       |
|   |                  EMERGENCY_CONTROLLER                     |                       |
|   |         (Emergency takes priority over Pedestrians)       |                       |
|   +-----------------------------------------------------------+                       |
+---------------------------------------------------------------------------------------+






## 2. Module Interface Definitions

### Module 1: `junction_fsm` (Instantiated as Junction A and Junction B)
Manages the finite state machine sequencing for North-South (NS) and East-West (EW) directions.

| Port Name | Direction | Width | Purpose / Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 bit | Global system clock |
| `rst_n` | Input | 1 bit | Active-low synchronous reset |
| `sync_trigger` | Input | 1 bit | 1-cycle pulse input initiating NS Green (used by Junction B) |
| `ped_grant` | Input | 1 bit | Grant signal allowing pedestrian crossing phase |
| `emergency_hold` | Input | 1 bit | Override signal forcing transition to ALL_RED within 2 cycles |
| `ped_request` | Output | 1 bit | Crosswalk request sent to Pedestrian Arbiter |
| `junction_state` | Output | 2 bits | Current junction state (`00`=ALL_RED, `01`=YELLOW, `10`=GREEN, `11`=PED) |
| `ns_light` | Output | 2 bits | North-South light state (`00`=Red, `01`=Yellow, `10`=Green, `11`=Ped) |
| `ew_light` | Output | 2 bits | East-West light state (`00`=Red, `01`=Yellow, `10`=Green, `11`=Ped) |
| `ns_green_active` | Output | 1 bit | Active high when North-South direction enters `NS_GREEN` state |

---

### Module 2: `green_wave_sync`
Tracks a configurable delay (`GREEN_WAVE_DELAY` clock cycles) after Junction A enters `NS_GREEN`, then fires a single-cycle pulse.

| Port Name | Direction | Width | Purpose / Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 bit | Global system clock |
| `rst_n` | Input | 1 bit | Active-low synchronous reset |
| `junc_a_ns_green` | Input | 1 bit | Active high when Junction A enters `NS_GREEN` |
| `sync_trigger_b` | Output | 1 bit | 1-cycle pulse generated when delay counter equals `GREEN_WAVE_DELAY` |

---

### Module 3: `pedestrian_arbiter`
Central arbiter receiving pedestrian crossing requests and current junction states to issue pedestrian grants using Round-Robin arbitration.

| Port Name | Direction | Width | Purpose / Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 bit | Global system clock |
| `rst_n` | Input | 1 bit | Active-low synchronous reset |
| `req_a` | Input | 1 bit | Pedestrian crossing request from Junction A |
| `req_b` | Input | 1 bit | Pedestrian crossing request from Junction B |
| `junction_a_state` | Input | 2 bits | Current state of Junction A (used to verify safe ALL_RED phase) |
| `junction_b_state` | Input | 2 bits | Current state of Junction B (used to verify safe ALL_RED phase) |
| `grant_a` | Output | 1 bit | Pedestrian crossing grant sent to Junction A |
| `grant_b` | Output | 1 bit | Pedestrian crossing grant sent to Junction B |

---

### Module 4: `emergency_controller`
Handles master emergency override, asserting priority over standard traffic sequencing and pedestrian requests.

| Port Name | Direction | Width | Purpose / Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 bit | Global system clock |
| `rst_n` | Input | 1 bit | Active-low synchronous reset |
| `emergency_in` | Input | 1 bit | Global emergency override sensor input |
| `emergency_hold` | Output | 1 bit | Master stop signal forcing both Junction FSMs to ALL_RED within 2 clock cycles |



## 3. Architectural Justifications & Control Logic

### Explicit Startup & Reset Sequence
1. `rst_n = 0` $\rightarrow$ Both Junction A and Junction B are forced to `ALL_RED` (`00`).
2. `rst_n = 1` $\rightarrow$ System recovers from reset; Junction A enters `NS_GREEN` state while Junction B remains in `ALL_RED` awaiting its sync trigger.
3. System transitions into normal traffic control operations.

### Green-Wave Synchronization Logic
* `GREEN_WAVE_DELAY` is defined as a configurable parameter specifying the exact number of clock cycles between Junction A's `NS_GREEN` activation and Junction B's trigger.
* When `junc_a_ns_green` goes high, an internal counter increments until reaching `GREEN_WAVE_DELAY`, whereupon a **1-cycle active-high pulse** (`sync_trigger_b`) is emitted to trigger Junction B.

### Strict Round-Robin Arbitration & Pedestrian Grant Phase
* **Arbitration Policy:** Uses explicit **Round-Robin** scheduling to eliminate starvation. If `req_a` and `req_b` arrive simultaneously, priority alternates based on the last served request (e.g., if Junction A was granted previously, Junction B receives priority).
* **Safe Grant Execution:** A pedestrian request can only be granted when the corresponding junction FSM reaches a valid `ALL_RED` phase, ensuring moving traffic is completely stopped before granting crosswalk signals.

### Emergency Override Priority
* `emergency_hold` takes supreme priority over normal state sequencing and pedestrian requests.
* When asserted, both junctions transition to `ALL_RED` within **maximum 2 clock cycles**.
* Any active or pending pedestrian request is overridden and ignored until the emergency state is cleared.




## 4. Verification Plan (Test Scenarios Matrix)

| Test ID | Test Category | Scenario Description | Expected Outcome / Result |
| :---: | :--- | :--- | :--- |
| **TC_01** | Reset | Assert active-low reset `rst_n = 0` during active operation. | System immediately forces both Junction A and Junction B to `ALL_RED` (`00`). |
| **TC_02** | Reset Recovery | De-assert reset (`rst_n = 1`). | System transitions cleanly to startup state (Junction A `NS_GREEN`, Junction B `ALL_RED`). |
| **TC_03** | Normal Operation | Run Junction A without pedestrian/emergency intervention. | Follows deterministic sequence: `NS_GREEN` -> `YELLOW` -> `ALL_RED` -> `EW_GREEN` -> `YELLOW` -> `ALL_RED`. |
| **TC_04** | Normal Operation | Run Junction B independently after receiving `sync_trigger_b`. | Follows standard NS/EW light timing sequence within bounds. |
| **TC_05** | Green-Wave Sync | Junction A transitions to `NS_GREEN`. | `green_wave_sync` counts `GREEN_WAVE_DELAY` cycles, then outputs a 1-cycle `sync_trigger_b` pulse. |
| **TC_06** | Green-Wave Timing | Verify Junction B start timing relative to Junction A. | Junction B `NS_GREEN` phase begins exactly `GREEN_WAVE_DELAY` clock cycles after Junction A `NS_GREEN` begins. |
| **TC_07** | Pedestrian Request | Assert `req_a = 1` while Junction A reaches `ALL_RED`. | `pedestrian_arbiter` issues `grant_a = 1`; Junction A enters `PED` phase. |
| **TC_08** | Pedestrian Request | Assert `req_b = 1` while Junction B reaches `ALL_RED`. | `pedestrian_arbiter` issues `grant_b = 1`; Junction B enters `PED` phase. |
| **TC_09** | Round-Robin Fairness | Assert `req_a = 1` and `req_b = 1` simultaneously on same clock edge. | Arbiter grants priority to the ungranted junction from the prior cycle, alternating fairly. |
| **TC_10** | Starvation Prevention | Hold `req_a = 1` continuously while asserting `req_b = 1`. | Arbiter services Junction A, then forces a grant to Junction B before Junction A can re-grant. |
| **TC_11** | Emergency Override | Assert global `emergency_in = 1` during `GREEN` phase. | Both Junction FSMs transition to `ALL_RED` within 2 clock cycles. |
| **TC_12** | Emergency Override | Assert global `emergency_in = 1` during active `PED` phase. | Active pedestrian grants are revoked and all junctions switch to `ALL_RED` within 2 clock cycles. |
| **TC_13** | Emergency Recovery | De-assert `emergency_in = 0`. | System clears hold and safely restarts from the default startup sequence without race conditions. |
| **TC_14** | Emergency Priority | Assert `req_a = 1` simultaneously with `emergency_in = 1`. | Emergency override takes total priority; `grant_a` remains `0` until emergency clears. |
| **TC_15** | Repeated Sync Pulse | Apply repeated `sync_trigger_b` pulses while Junction B is active in `NS_GREEN`. | Junction B FSM ignores redundant triggers and maintains stable state execution without restarting timing. |ge Case | Rapid toggling of `sync_trigger` from Green-Wave module. | Junction B FSM filters glitches and maintains stable timing transitions. |
