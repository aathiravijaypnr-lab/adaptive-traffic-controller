# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)

[![Verilog HDL](https://img.shields.io/badge/Language-Verilog%20HDL-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Verification](https://img.shields.io/badge/Verification-ModelSim%20Self--Checking-success.svg)](https://github.com/aathiravijaypnr-lab/adaptive-traffic-controller)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)](https://github.com/aathiravijaypnr-lab/adaptive-traffic-controller)

---

## 1. Project Overview
The **Adaptive Multi-Junction Traffic Grid Controller (AMTGC)** is a modular, single-clock digital hardware design written in Verilog HDL. It coordinates two 4-way traffic intersections (Junction A and Junction B) with:
* **Green-Wave Synchronization:** Automatically offsets Junction B's North–South green phase relative to Junction A using a configurable delay line.
* **Traffic-Adaptive Timing:** Dynamically scales green phase durations based on a 3-bit `traffic_density` input while strictly clamping values between safe `MIN_GREEN_TIME` and `MAX_GREEN_TIME` bounds.
* **Shared Fair Pedestrian Arbiter:** Resolves crosswalk requests via a round-robin scheduling policy to completely prevent starvation.
* **System-Wide Emergency Override:** Forces all junction controllers into a safe all-red state within bounded clock cycles upon activation.

---

## 2. Repository Directory Structure
```text
adaptive-traffic-controller/
├── rtl/
│   ├── amtgc_top.v                 # Top-level integration module
│   ├── junction_controller.v       # 8-state Moore FSM & adaptive green logic
│   ├── generic_timer.v             # Standalone parameterized timing module
│   ├── ped_arbiter.v               # Shared round-robin pedestrian arbiter
│   └── green_wave_sync.v           # Green-wave synchronization block
├── tb/
│   └── amtgc_top_tb.v              # Unified self-checking testbench (39 assertions)
├── docs/
│   ├── technical_report.md         # Comprehensive engineering technical report
│   ├── bug_log.md                  # Development bug tracking and resolutions log
│   ├── assumptions.md              # Architectural assumptions and design constraints
│   ├── self_attestation_checklist.md # Self-attestation compliance checklist
│   ├── amtgc_top_block_diagram.png # Top-level architecture block diagram
│   └── junction_controller_diagram.png # Junction controller internal schematic
└── sim/
    ├── transcript                    # ModelSim execution log
    └── waveforms/                    # Simulation waveform screenshots (.png)
```
---


### 3. Top-Level Architecture & Signal Interfaces
graph TB
    subgraph amtgc_top [AMTGC Top-Level Integration]
        direction TB
        JA[Junction A Controller] -->|Timer Limit / Start| TA[Generic Timer A]
        TA -->|Timer Expired| JA
        
        JB[Junction B Controller] -->|Timer Limit / Start| TB[Generic Timer B]
        TB -->|Timer Expired| JB
        
        JA -->|state_a| GWS[Green Wave Synchronization]
        GWS -->|sync_trigger| JB
        
        JA -->|ped_ready_a| PA[Shared Pedestrian Arbiter]
        JB -->|ped_ready_b| PA
        PA -->|ped_grant_a & b| JA
        PA -->|ped_grant_b| JB
        
        EO[Emergency Override] -->|emg_active| JA
        EO -->|emg_active| JB
    end
Key Interface Ports (amtgc_top.v)Port NameDirectionWidthDescriptionclkInput1 bitGlobal system clockrst_nInput1 bitActive-low asynchronous resetped_req_a, ped_req_bInputs1 bit eachPedestrian crossing requestsemergency_overrideInput1 bitSystem-wide emergency stop signaldensity_a, density_bInputs3 bits eachTraffic density inputs ($0–7$)state_a, state_bOutputs3 bits eachEncoded FSM current statessync_triggerOutput1 bitObservable green-wave synchronization pulse4. Software Prerequisites & Simulation ToolsTo compile and simulate this design, you will need:Simulator: ModelSim (Intel FPGA Starter Edition, Mentor Graphics, or QuestaSim) supporting Verilog-2001.Command Line Tools: Git and a terminal (Bash/PowerShell).5. Step-by-Step Simulation Instructions
Clone the repository and run the simulation using ModelSim from your terminal:Bash
# 1. Clone the public repository
git clone [https://github.com/aathiravijaypnr-lab/adaptive-traffic-controller.git](https://github.com/aathiravijaypnr-lab/adaptive-traffic-controller.git)
cd adaptive-traffic-controller

# 2. Create a working simulation directory
mkdir -p work
vlib work

# 3. Compile the RTL source files and unified testbench
vlog -work work rtl/*.v tb/*.v

# 4. Launch the ModelSim simulator with self-checking assertions enabled
vsim -c -voptargs="+acc" work.amtgc_top_tb -do "run -all; quit"
---

###6. Verification Summary & Test MatrixThe unified self-checking testbench (amtgc_top_tb.v) executes 39 automated assertions distributed across 6 test suites, followed by a 1,000-cycle constrained-random stress test:Test SuiteFocus AreaStatus / ResultTest 1Reset & Recovery (Phase coverage)PASS (6/6 checks)Test 2Emergency Preemption SweepPASS (10/10 checks)Test 3Rapid Emergency Toggling (100 cycles)PASS (1/1 checks)Test 4Pedestrian Round-Robin FairnessPASS (3/3 checks)Test 5Adaptive Timing & Green-Wave IntegrityPASS (18/18 checks)Test 61,000-Cycle Constrained-Random Stress TestPASS (Zero invariants violated)TOTALComprehensive System Verification39 PASS / 0 FAIL


###7. Author & AcknowledgmentsAuthor: Aathira VijayInstitution: Electronics and Communication EngineeringProject Reference: Adaptive Multi-Junction Traffic Grid Controller (AMTGC) VLSI Design Course.    
