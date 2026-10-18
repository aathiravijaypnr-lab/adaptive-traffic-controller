# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)
## Technical Report & Architectural Specification

**Author:** Aathira Vijay  
**Repository:** [adaptive-traffic-controller](https://github.com/aathiravijaypnr-lab/adaptive-traffic-controller)  
**Date:** October 18, 2026  
**Document Version:** 1.0  

---

## Executive Abstract

This report presents the architectural design, Verilog RTL implementation, and full self-checking simulation verification of an Adaptive Multi-Junction Traffic Grid Controller (AMTGC). The system manages two 4-way traffic intersections (Junction A and Junction B) within a synchronized traffic grid. Key features include dynamic traffic-density-based green timing adjustments, a green-wave synchronization offset between North-South green phases to optimize traffic flow, a shared round-robin pedestrian arbiter to eliminate pedestrian starvation, and an immediate system-wide emergency override that safely forces all traffic signals to an all-red state within a bounded number of clock cycles. 

The design is fully parameterized and adheres to a strict single clock domain with synchronous active-low reset strategy. Verification was executed in ModelSim using an automated, self-checking testbench comprising 39 assertions, directed test scenarios, and a 1,000-cycle constrained-random stress sweep with zero invariant violations.

---

## 1. Introduction & System Specifications

### 1.1 Project Overview
Modern urban traffic management requires coordinated signal logic to minimize congestion, handle variable traffic density, ensure pedestrian safety, and accommodate emergency vehicles. The AMTGC system unifies two traffic junctions (Junction A and Junction B) into a coordinated hardware system built entirely in parameterized Verilog RTL.

### 1.2 System Specifications & Requirements
- **Single Clock Domain:** Fully synchronous logic operating on `clk` with active-low synchronous reset `rst_n`.
- **4-Way Traffic Signal Control:** Each junction sequences North-South (NS) and East-West (EW) directions through `GREEN`, `YELLOW`, and `ALL-RED` safety gap phases.
- **Parametric Timing:** Modular FSM controllers configured using parameters (`GREEN_TIME`, `YELLOW_TIME`, `RED_TIME`, `PED_TIME`) avoiding hardcoded magic numbers.
- **Traffic-Adaptive Green Duration:** Dynamic green light extension calculated based on a 3-bit `traffic_density` input (values 0–7), strictly bounded by `MIN_GREEN_TIME` and `MAX_GREEN_TIME`.
- **Green-Wave Synchronization Link:** Junction B delays its NS Green phase relative to Junction A's NS Green start by a fixed, predictable cycle offset to facilitate smooth vehicle flow.
- **Shared Pedestrian Arbitration:** A centralized `ped_arbiter` serves pedestrian walk requests from both junctions using a fair round-robin policy to prevent starvation.
- **Emergency Override:** System-wide `emergency_override` input forcing both junctions to an All-Red safety state within $\le 2$ clock cycles upon assertion.

---

## 2. System Architecture & Module Interface Contracts

### 2.1 Top-Level Architecture Overview
The system is structured hierarchically inside the top-level wrapper module `amtgc_top.v`. It integrates two instances of `junction_controller.v` (Junction A and Junction B), two standalone instances of `generic_timer.v`, a central `ped_arbiter.v`, a dedicated `green_wave_sync.v` block, and top-level emergency override gating logic.

+-------------------------------------------------------------+
                              |                         amtgc_top                           |
                              |                                                             |
clk, rst_n ------------------->|---> Junction A (junction_controller)                        |
emergency_override ----------->|     +---> timer_inst (generic_timer)                        |
|     |                                                       |
traffic_density_a [2:0] ------>|-----> NS / EW / Pedestrian Phase Logic ------+                |
ped_req_a -------------------->|                                            |                |
|                                            v                |
|                                   +-----------------+       |
|                                   |   ped_arbiter   |       |
|                                   |  (Round-Robin)  |       |
|                                   +-----------------+       |
traffic_density_b [2:0] ------>|-----> NS / EW / Pedestrian Phase Logic ------^                |
ped_req_b -------------------->|     |                                                       |
|     +---> timer_inst (generic_timer)                        |
|---> Junction B (junction_controller)                        |
|                                                             |
|---> green_wave_sync                                         |
+-------------------------------------------------------------+


### 2.2 Why Modules Exist Separately
1. **`generic_timer.v`**: Designed as a pure, standalone hardware counter module with parameter `COUNTER_WIDTH`. Keeping timing counter registers out of the state machine prevents logic bloat and guarantees true modular reusability.
2. **`junction_controller.v`**: Implements the Moore Finite State Machine governing phase transitions for a single 4-way intersection. It computes dynamic count targets based on traffic density and delegates actual cycle counting to `generic_timer`.
3. **`ped_arbiter.v`**: Centralizes crosswalk request handling. Having a shared arbiter rather than separate controllers ensures fair mutual exclusion when pedestrians attempt to cross both junctions simultaneously.
4. **`green_wave_sync.v`**: Manages the delay offset trigger between Junction A's North-South green start and Junction B's North-South green start, ensuring arterial progression across the grid.

### 2.3 Module Interface Specification

#### Top-Level `amtgc_top.v` Interface
| Signal Name | Direction | Bit Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1 | Global system clock domain |
| `rst_n` | Input | 1 | Synchronous active-low system reset |
| `emergency_override` | Input | 1 | Global override forcing all directions to All-Red |
| `ped_req_a` | Input | 1 | Pedestrian crosswalk button request for Junction A |
| `ped_req_b` | Input | 1 | Pedestrian crosswalk button request for Junction B |
| `traffic_density_a` | Input | 3 | Traffic density level (0–7) for Junction A |
| `traffic_density_b` | Input | 3 | Traffic density level (0–7) for Junction B |
| `ns_green_a`, `ns_yellow_a` | Output | 1 | North-South traffic light outputs for Junction A |
| `ew_green_a`, `ew_yellow_a` | Output | 1 | East-West traffic light outputs for Junction A |
| `ped_walk_a` | Output | 1 | Pedestrian crosswalk grant light output for Junction A |
| `ns_green_b`, `ns_yellow_b` | Output | 1 | North-South traffic light outputs for Junction B |
| `ew_green_b`, `ew_yellow_b` | Output | 1 | East-West traffic light outputs for Junction B |
| `ped_walk_b` | Output | 1 | Pedestrian crosswalk grant light output for Junction B |

---

## 3. Finite State Machine (FSM) Design

Each junction controller operates using a 6-state Moore Finite State Machine encoded with robust parameter constants:

              +-------------------+
              |   S_RESET (000)   | <--- (rst_n == 0)
              +-------------------+
                        |
                        v
              +-------------------+
              |  S_NS_GREEN (001) |
              +-------------------+
                        |
                        v
              +-------------------+
              | S_NS_YELLOW (010) |
              +-------------------+
                        |
                        v
              +-------------------+
              |  S_ALL_RED1 (011) |
              +-------------------+
                        |
        +---------------+---------------+
        |                               |
        v (ped_grant asserted)          v (normal cycle)
+-------------------+           +-------------------+
|  S_PED_WALK (110) |           |  S_EW_GREEN (100) |
+-------------------+           +-------------------+
|                               |
+---------------+---------------+
|
v
+-------------------+
| S_EW_YELLOW (101) |
+-------------------+
|
v
+-------------------+
|  S_ALL_RED2 (111) |
+-------------------+
|
+---> (Loop back to S_NS_GREEN)


### 3.1 State Definitions & Safety Rules
1. **`S_RESET (3'b000)`**: Default safe initialization state on reset. All lights output Red (low).
2. **`S_NS_GREEN (3'b001)`**: North-South directions given green passage. Active duration equals calculated dynamic green time.
3. **`S_NS_YELLOW (3'b010)`**: North-South yellow clearance interval (`YELLOW_TIME`).
4. **`S_ALL_RED1 (3'b011)`**: mandatory non-zero safety clearance gap where all directions display Red before transitioning to EW Green or Pedestrian Phase.
5. **`S_EW_GREEN (3'b100)`**: East-West directions given green passage.
6. **`S_EW_YELLOW (3'b101)`**: East-West yellow clearance interval.
7. **`S_PED_WALK (3'b110)`**: Pedestrian crossing phase entered safely following an All-Red safety gap when a pedestrian grant is acknowledged.
8. **`S_ALL_RED2 (3'b111)`**: Secondary All-Red safety clearance before cycling back to NS Green.

---

---

## 4. Implementation Details & Adaptive Logic

### 4.1 Parameterization & Hardware Reusability
Both traffic junctions are instantiated from the exact same `junction_controller.v` module inside `amtgc_top.v`. True parameterization is demonstrated by applying different timing parameters to each junction without altering any RTL code:
- **Junction A:** `GREEN_TIME = 10`, `YELLOW_TIME = 3`, `RED_TIME = 2`, `PED_TIME = 5`
- **Junction B:** `GREEN_TIME = 8`, `YELLOW_TIME = 3`, `RED_TIME = 2`, `PED_TIME = 5`

### 4.2 Traffic-Adaptive Green Duration
To optimize traffic flow, `junction_controller` dynamically calculates the required green cycle duration based on the 3-bit `traffic_density` input (range 0 to 7):
$$\text{Calculated Green Time} = \text{MIN\_GREEN\_TIME} + (\text{traffic\_density} \times \text{SCALE\_FACTOR})$$

To guarantee safety and prevent direction starvation or unstable cycling:
- **Minimum Bound (`MIN_GREEN_TIME`):** Ensured even when `traffic_density == 0`.
- **Maximum Bound (`MAX_GREEN_TIME`):** Strictly enforced as a cap even if density demands exceed safety limits.
- **Stable Sampling:** The `traffic_density` input is sampled exclusively at the start of a green phase to prevent mid-count target instability.

### 4.3 Centralized Fair Pedestrian Arbitration
The `ped_arbiter.v` module resolves crosswalk requests using a fair round-robin arbitration policy with state memory (`last_served`).
- If simultaneous requests arrive (`ped_req_a == 1` and `ped_req_b == 1`), the arbiter alternates priority to guarantee that neither junction suffers starvation.
- Requests arriving during active yellow or all-red phases are registered in request flip-flops and serviced during the next safe pedestrian window.

---

## 5. Verification Methodology & Simulation Results

### 5.1 Verification Strategy
Verification was conducted in ModelSim using an automated, self-checking top-level testbench (`tb/amtgc_top_tb.v`). The testbench integrates:
- **Automated Scoreboards & Assertions:** 39 dedicated assertion checks evaluating valid state encoding, all-red safety gaps, green-wave delay bounds, and emergency override response times.
- **Constrained-Random Stress Sweep:** A 1,000-cycle randomized stimulus generator applying unpredictable pedestrian requests and traffic density fluctuations.

### 5.2 Summary of Verification Results
'
==================================================================
                   AMGC TASK 5 VERIFICATION SUMMARY
==================================================================
TEST 1 - RESET & RECOVERY              : PASS=6  FAIL=0
TEST 2 - EMERGENCY PREEMPTION          : PASS=10 FAIL=0
TEST 3 - RAPID EMERGENCY TOGGLE        : PASS=1  FAIL=0
TEST 4 - PEDESTRIAN FAIRNESS           : PASS=3  FAIL=0
TEST 5 - ADAPTIVE + GREEN-WAVE         : PASS=18 FAIL=0
TEST 6 - CONSTRAINED RANDOM            : PASS=1  FAIL=0
------------------------------------------------------------------
TOTAL PASS CHECKS : 39
TOTAL FAIL CHECKS : 0
------------------------------------------------------------------
                  TASK 5 VERIFICATION PASSED!
==================================================================

5.3 Simulation Waveform EvidenceAll simulation waveform artifacts are captured and archived inside the /sim directory:Normal & Adaptive Operation (sim/waveform_normal_operation.png & sim/waveform_adaptive_timing.png): Demonstrates smooth phase transitions (NS Green $\rightarrow$ NS Yellow $\rightarrow$ All-Red $\rightarrow$ EW Green $\rightarrow$ EW Yellow $\rightarrow$ All-Red) with green duration scaling proportionally to traffic_density.Emergency Override (sim/waveform_emergency_override.png): Proves that asserting emergency_override = 1 immediately forces both junctions to an All-Red safety state within $\le 2$ clock cycles.Pedestrian Arbitration (sim/waveform_ped_arbiter.png): Confirms simultaneous pedestrian requests from Junction A and Junction B are granted fairly without starvation or double-servicing.6. Bug Log & Debug AnalysisDuring system design and verification, several edge-case bugs were identified, tracked, and resolved:Bug IDPhase DiscoveredDescription / Root CauseCorrective Action / RTL FixBUG-01Task 2 SimulationTimer failed to trigger done when count_target == 0.Updated generic_timer.v to assert done = 1 immediately upon start = 1 when count_target == 0.BUG-02Task 3 IntegrationFixed-priority arbitration caused Junction B pedestrian starvation during continuous simultaneous requests.Replaced fixed priority logic in ped_arbiter.v with a round-robin state register (last_served).BUG-03Task 4 Adaptive SweepFluctuating traffic_density during active green phase caused timer target jumps and glitched transitions.Added input latching in junction_controller.v to freeze traffic_density at phase entry.7. Conclusions & Deliverables ComplianceThe Adaptive Multi-Junction Traffic Grid Controller (AMTGC) project has been successfully planned, developed, integrated, and verified in full compliance with all specification requirements.Final Checklist of Deliverables[x] Clean hierarchical Verilog RTL (/rtl)[x] Automated self-checking testbenches (/tb)[x] Simulation log and archived waveform screenshots (/sim)[x] Architecture specifications, Bug Log, Assumptions, and Technical Report (/docs)[x] Public, structured GitHub Repository with informative README.md
