# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)

![Language](https://img.shields.io/badge/Language-Verilog%20HDL-blue.svg)
![Simulation](https://img.shields.io/badge/Simulation-ModelSim-success.svg)
![Verification](https://img.shields.io/badge/Verification-39%20PASS%20%7C%200%20FAIL-brightgreen.svg)
![Project](https://img.shields.io/badge/Project-VLSI%20Design-orange.svg)

---

## 1. Project Overview

The **Adaptive Multi-Junction Traffic Grid Controller (AMTGC)** is a modular digital traffic-control system implemented in Verilog HDL. It coordinates two four-way traffic intersections, Junction A and Junction B, using independent junction controllers and timers.

### Key Features

- **Adaptive Green Timing:** Adjusts green-phase duration according to traffic density, within configurable minimum and maximum limits.
- **Green-Wave Synchronization:** Uses Junction A's state information to generate a synchronization trigger for Junction B.
- **Shared Pedestrian Arbitration:** Coordinates pedestrian requests from both junctions through a shared arbiter.
- **Emergency Handling:** Distributes an emergency override to both junction controllers and gates relevant top-level signals.
- **Finite State Machine Control:** Uses an eight-state Moore-style FSM in each junction controller.
- **Modular RTL Design:** Separates junction control, timing, pedestrian arbitration, and synchronization into individual modules.

The design is simulated and verified using ModelSim.

---

## 2. Repository Directory Structure

```text
adaptive-traffic-controller/
├── README.md
├── rtl/
│   ├── amtgc_top.v
│   ├── junction_controller.v
│   ├── generic_timer.v
│   ├── ped_arbiter.v
│   └── green_wave_sync.v
├── tb/
│   ├── amtgc_top_tb.v
│   ├── generic_timer_tb.v
│   └── junction_controller_tb.v
├── docs/
│   ├── technical_report.md
│   ├── bug_log.md
│   ├── assumptions.md
│   ├── self_attestation_checklist.md
│   ├── amtgc_top_block_diagram.png
│   └── junction_controller_diagram.png
└── sim/
    ├── simulation_run.log
    ├── waveform_normal_operation.png
    ├── waveform_emergency_override.png
    ├── waveform_ped_arbiter.png
    └── waveform_adaptive_timing.png
```



---

## 3. System Architecture

The top-level module, `amtgc_top`, integrates the two junction controllers, their independent timers, the shared pedestrian arbiter, the green-wave synchronization module, and emergency-control logic.

### Module Descriptions

| Module | Description |
|---|---|
| `amtgc_top.v` | Integrates the system components and manages top-level signal connections. |
| `junction_controller.v` | Implements the eight-state FSM, adaptive green-time calculation, phase transitions, and traffic/pedestrian outputs. |
| `generic_timer.v` | Provides timer functionality for each junction. |
| `ped_arbiter.v` | Coordinates pedestrian requests from both junctions. |
| `green_wave_sync.v` | Observes Junction A's state and generates a synchronization trigger for Junction B. |

### System Operation

1. Both junction controllers receive the common clock and reset signals, along with their respective traffic-density inputs.
2. Each controller communicates with its own generic timer.
3. The shared pedestrian arbiter coordinates pedestrian requests and grants.
4. The green-wave synchronization module observes `state_a` and generates `sync_trigger_raw`.
5. The top-level module gates the synchronization trigger during an emergency before passing `sync_trigger` to Junction B.
6. The emergency override is distributed to both junction controllers and used in relevant top-level gating logic.

Refer to the following diagram,

`docs/amtgc_top_block_diagram.png`

---

## 4. Top-Level Interface

The following table describes the principal ports of `amtgc_top`.

| Signal | Direction | Width | Description |
|---|---|---|---|
| `clk` | Input | 1 bit | Common system clock. |
| `rst_n` | Input | 1 bit | Active-low asynchronous reset. |
| `ped_req_a` | Input | 1 bit | Pedestrian request for Junction A. |
| `ped_req_b` | Input | 1 bit | Pedestrian request for Junction B. |
| `emergency_override` | Input | 1 bit | System-wide emergency override. |
| `density_a` | Input | 3 bits | Traffic-density input for Junction A. |
| `density_b` | Input | 3 bits | Traffic-density input for Junction B. |
| `state_a` | Output | 3 bits | Encoded FSM state of Junction A. |
| `state_b` | Output | 3 bits | Encoded FSM state of Junction B. |
| `sync_trigger` | Output | 1 bit | Observable, emergency-gated synchronization trigger. |

The top-level module also exposes traffic-light outputs and pedestrian-walk outputs for both junctions. Refer to `rtl/amtgc_top.v` for the complete port list.

---

## 5. Adaptive Green-Time Calculation

The green duration is calculated using the following expression:

```text
green_time = MIN_GREEN_TIME
           + traffic_density * GREEN_EXTENSION
```

The calculated value is clamped between the configured minimum and maximum green times.

### Default Parameters

| Parameter | Default Value | Description |
|---|---:|---|
| `MIN_GREEN_TIME` | 5 | Minimum green-phase duration. |
| `MAX_GREEN_TIME` | 10 | Maximum green-phase duration. |
| `GREEN_EXTENSION` | 1 | Additional duration per density level. |

### Green Time by Traffic Density

| Traffic Density | Green Time |
|---:|---:|
| 0 | 5 |
| 1 | 6 |
| 2 | 7 |
| 3 | 8 |
| 4 | 9 |
| 5 | 10 |
| 6 | 10 |
| 7 | 10 |

The controller samples the calculated duration when entering a green phase.

These values represent timer counts or simulation time units according to the timer implementation and clock configuration.
---

## 6. Junction Controller FSM

Each junction controller implements an eight-state finite state machine.

| State | Encoding | Description |
|---|---|---|
| `ST_RESET` | `000` | Initial reset state. |
| `ST_NS_GREEN` | `001` | North–south green phase. |
| `ST_NS_YELLOW` | `010` | North–south yellow phase. |
| `ST_EW_GREEN` | `011` | East–west green phase. |
| `ST_EW_YELLOW` | `100` | East–west yellow phase. |
| `ST_PED_WALK` | `101` | Pedestrian-walk phase. |
| `ST_ALL_RED` | `110` | All vehicle green/yellow outputs are inactive. |
| `ST_EMERGENCY` | `111` | Emergency-handling state. |

The FSM uses timer-expiration events and additional control conditions to determine phase transitions.

Emergency handling has priority in the state register. While `emg_active` is asserted, the controller disables vehicle green/yellow and pedestrian-walk outputs.

The controller does not expose dedicated red-light output ports. The all-red condition is represented by the vehicle green/yellow outputs being inactive.

---

## 7. Prerequisites

The following tools are required to compile and simulate the project:

- **ModelSim:** Intel FPGA Edition, QuestaSim, or another compatible Verilog simulator.
- **Git:** For cloning the repository.

---

## 8. Simulation Instructions

### Step 1: Clone the Repository

```bash
git clone https://github.com/aathiravijaypnr-lab/adaptive-traffic-controller.git
cd adaptive-traffic-controller
```

### Step 2: Create the Simulation Library

Run the following command in the ModelSim Transcript window:

```tcl
vlib work
```

### Step 3: Compile the RTL and Testbench

```tcl
vlog rtl/*.v tb/*.v
```

### Step 4: Run the Testbench

```tcl
vsim work.amtgc_top_tb
run -all
```



### Step 5: Inspect Waveforms

For graphical waveform verification:

1. Open the project in ModelSim.
2. Compile the RTL and testbench.
3. Load `amtgc_top_tb`.
4. Add the relevant signals to the Wave window.
5. Run the simulation.
6. Inspect state transitions, traffic-light outputs, timer behavior, pedestrian arbitration, synchronization, and emergency handling.



---

## 9. Verification Summary

The simulation summary reported for this project is **39 PASS and 0 FAIL**.

| Test Suite | Verification Focus | Reported Result |
|---|---|---|
| Test 1 | Reset and recovery | PASS — 6 checks |
| Test 2 | Emergency preemption | PASS — 10 checks |
| Test 3 | Rapid emergency toggling | PASS — 1 check |
| Test 4 | Pedestrian arbitration fairness | PASS — 3 checks |
| Test 5 | Adaptive timing and green-wave integrity | PASS — 18 checks |
| Test 6 | 1,000-cycle constrained-random stress test | PASS — zero new invariant violations |
| **Total** | **Reported testbench summary** | **39 PASS / 0 FAIL** |



---

## 10. Project Documentation

The `docs/` directory contains the following supporting project documents:

| File | Purpose |
|---|---|
| `technical_report.md` | Project overview, architecture, RTL design, FSM operation, verification methodology, simulation results, and conclusion. |
| `bug_log.md` | Development issues, their causes, and resolutions. |
| `assumptions.md` | Design assumptions, constraints, and implementation decisions. |
| `self_attestation_checklist.md` | Submission and compliance checklist. |
| `amtgc_top_block_diagram.png` | Top-level system architecture diagram. |
| `junction_controller_diagram.png` | Junction-controller block diagram. |

---

## 11. Limitations and Scope

AMTGC is a digital RTL design evaluated through simulation. The reported results do not constitute validation on physical traffic-light hardware or a real road network.

The behavior of the design depends on the implemented FSM transitions, timer semantics, arbitration logic, synchronization logic, parameter values, and testbench coverage.

Deployment in a real traffic-control environment would require additional safety analysis, hardware integration, and system-level validation.

---

## 12. Project Demonstration Video

The demonstration covers the AMTGC architecture, Verilog RTL implementation, ModelSim simulation, and waveform verification.

**Watch the demo:** [AMTGC Demo Video](https://drive.google.com/file/d/1rWQTwJc1i9ZbSHjDYYRyGAYAQaz3_4Ql/view?usp=drive_link)

---

## 13. Author and Project Reference

- **Author:** Aathira Vijay
- **Field of Study:** Electronics and Communication Engineering
- **Project:** Adaptive Multi-Junction Traffic Grid Controller (AMTGC)
- **Project Context:** VLSI design using Verilog HDL and ModelSim

---

*For implementation details, refer to the RTL source files. For verification evidence, refer to the committed simulation transcript and waveforms.*
