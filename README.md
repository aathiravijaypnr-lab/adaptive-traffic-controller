# adaptive-traffic-controller - System Architecture Plan

## 1. Top-Level System Architecture

The system is designed as a modular, single-clock digital system that controls two 4-way traffic junctions (Junction A and Junction B) with green-wave coordination, a shared pedestrian arbiter, and a central emergency override controller.

+-------------------------------------------------------------------------------+
|                             ADAPTIVE_TRAFFIC_TOP                               |
|                                                                                |
|            (1) Green Wave Sync Control                                         |
|         +------------------------------------------------------+               |
|         |                     Controls                          |              |
|  +------|----+  (A turns   +--+------------------+  (Starts    +-----|------+  |
|  | Junction A |   green)   |  | Green Wave Sync  |   timer for | Junction B |  |
|  | Traffic   |------------>|  | Coordination     |------------>| Traffic    |  |
|  | FSM Logic  |            |  |                  |             | FSM Logic  |  |
|  +------|----+            +--+------------------+             +------|----+    |
|         |                                                            |         |
|         |           (2) Shared Pedestrian requests & Grants          |         |
|         +------------------------------------------------------+     |         |
|  ped_req_a           ped_grant_a                   ped_req_b         |         |
|    |                      ^                          |               |         |
|    v                      |                          v               |         |
| +--+----------------------|---+                   +--+---------------v-+       |
| |                             |                   |                    |       |
| | Shared Pedestrian Arbiter  |                   | Junction B Status  |        |
| | Logic                       |                   |                    |       |
| +--+----------------------+---+                   +--+-----------------+       |
|    |                                                 |                         |
|    |               (3) Global Emergency Override Control                       |
|    +------------------------------------------------------+                    |
|                                                 Controls                       |
|   +-----------------------+              +--+-------------+-------+            |
|   | Emergency Controller  |    Broadcasts|  |             |        |           |
|   | Global Stop Signals  |------------->|  | Junction A  | Junction B |        |
|   +-----------------------+              |  | Override    | Override    |      |
|                                          +--+-------------+-------------+      |
+-------------------------------------------------------------------------------+







## 2. Module Interface Definitions

This section details the inputs, outputs, signal widths, and functionality for each individual sub-module in the system.

### Module 1: `junction_fsm` (Instantiated as Junction A and Junction B)
Manages the finite state machine sequencing (Green -> Yellow -> Red) for North-South and East-West directions.

| Port Name | Direction | Width | Purpose / Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 bit | Global system clock |
| `rst_n` | Input | 1 bit | Active-low synchronous reset |
| `sync_trigger` | Input | 1 bit | Trigger signal to initiate Green phase (used by Junction B) |
| `ped_grant` | Input | 1 bit | Grant signal allowing pedestrian crossing phase |
| `emergency_hold` | Input | 1 bit | Override signal to force immediate transition to All-Red |
| `ped_request` | Output | 1 bit | Crosswalk request sent to Shared Pedestrian Arbiter|
| `ns_light` | Output | 2 bits | North-South light state (`00`=Red, `01`=Yellow, `10`=Green, `11`=Ped) |
| `ew_light` | Output | 2 bits | East-West light state (`00`=Red, `01`=Yellow, `10`=Green, `11`=Ped) |
| `ns_green_active` | Output | 1 bit | High when North-South direction is Green (used for Green-Wave sync) |

---

### Module 2: `green_wave_sync`
Tracks the time delay after Junction A turns North-South Green and signals Junction B to start its Green phase[cite: 1].

| Port Name | Direction | Width | Purpose / Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 bit | Global system clock |
| `rst_n` | Input | 1 bit | Active-low synchronous reset |
| `junc_a_ns_green` | Input | 1 bit | Active signal from Junction A indicating NS Green is active |
| `sync_trigger_b` | Output | 1 bit | Pulse output triggering Junction B's NS Green after fixed delay |

---

### Module 3: `pedestrian_arbiter`
Central arbiter receiving pedestrian crossing requests from both junctions and granting them fairly.

| Port Name | Direction | Width | Purpose / Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 bit | Global system clock |
| `rst_n` | Input | 1 bit | Active-low synchronous reset |
| `req_a` | Input | 1 bit | Pedestrian crossing request from Junction A |
| `req_b` | Input | 1 bit | Pedestrian crossing request from Junction B |
| `grant_a` | Output | 1 bit | Pedestrian crossing grant sent to Junction A |
| `grant_b` | Output | 1 bit | Pedestrian crossing grant sent to Junction B |

---

### Module 4: `emergency_controller`
Handles the master emergency override signal to safely stop all traffic across both junctions.

| Port Name | Direction | Width | Purpose / Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 bit | Global system clock |
| `rst_n` | Input | 1 bit | Active-low synchronous reset |
| `emergency_in` | Input | 1 bit | Global emergency override switch/sensor input |
| `emergency_hold` | Output | 1 bit | Master stop signal sent to both Junction FSMs |




## 3. Architectural Justifications & Reset Strategy

### Architectural Justifications
* **Modular Design Principles:** Separating the system into distinct sub-modules (`junction_fsm`, `green_wave_sync`, `pedestrian_arbiter`, and `emergency_controller`) ensures clean isolation of concerns. This modularity makes debugging straightforward, enhances code reusability, and simplifies formal verification and testing.
* **Shared Pedestrian Arbiter:** Using a single shared arbiter instead of duplicating controllers at each junction prevents hardware redundancy and centralizes fairness logic.
* **Starvation Avoidance:** The pedestrian arbiter implements Round-Robin / First-Come First-Served fairness. If both junctions request pedestrian walk time simultaneously, the arbiter alternates priority between Junction A and Junction B, ensuring neither request waits indefinitely.

---

### Clocking & Reset Strategy
* **Single Clock Domain:** All modules operate on a unified system clock (`clk`). This eliminates Clock Domain Crossing (CDC) issues, guarantees deterministic state transitions, and simplifies timing analysis across module interfaces.
* **Synchronous Active-Low Reset (`rst_n`):** The system uses a synchronous active-low reset. Reset evaluation occurs strictly on the rising edge of the system clock, preventing false triggers caused by noise or signal glitches on the reset line. This ensures predictable and safe transitions into the initial reset state.
