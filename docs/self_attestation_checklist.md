# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)
## Self-Attestation Checklist

This document serves as a formal self-verification declaration by the author, confirming that all functional requirements, coding standards, verification targets, and repository guidelines have been meticulously reviewed and fulfilled prior to final submission.

---

### 1. Repository Structure & Organization
- [x] Repository visibility is set to **Public** for accessibility.
- [x] Folder structure strictly adheres to the prescribed layout: `/rtl`, `/tb`, `/docs`, and `/sim`.
- [x] All Verilog source files are placed inside `/rtl` with proper `.v` extensions.
- [x] All testbenches are stored inside `/tb`.
- [x] Required documentation (`technical_report.md`, `bug_log.md`, `assumptions.md`, and this checklist) are located inside `/docs`.
- [x] Simulation transcript logs and clean waveform screenshots (`.png`) are archived inside `/sim`.

### 2. RTL Design & Coding Standards
- [x] All modules use a **single clock domain** (`clk`) with a synchronous active-low reset (`rst_n`).
- [x] True hardware parameterization is implemented using parameters (`GREEN_TIME`, `YELLOW_TIME`, `RED_TIME`, `COUNTER_WIDTH`) avoiding hardcoded magic numbers.
- [x] The **`generic_timer.v`** module remains completely standalone and reusable without modification.
- [x] Sequential logic exclusively uses non-blocking (`<=`) assignments, while combinational logic uses blocking (`=`) assignments.
- [x] All FSM `case` statements include an explicit `default` case to prevent unintended latch inference.
- [x] A non-zero All-Red safety clearance gap is strictly enforced between conflicting traffic directions.

### 3. System Integration & Advanced Features
- [x] Top-level integration (`amtgc_top.v`) instantiates two junctions with distinct timing parameter configurations.
- [x] Green-wave coordination link successfully synchronizes Junction B's North-South green start relative to Junction A.
- [x] Centralized pedestrian arbiter (`ped_arbiter.v`) implements a fair round-robin policy, eliminating starvation during simultaneous requests.
- [x] Global emergency override successfully forces both junctions into a safe All-Red state within bounded clock cycles.
- [x] Traffic-adaptive green timing dynamically scales based on `traffic_density` while strictly respecting `MIN_GREEN` and `MAX_GREEN` safety bounds.

### 4. Verification & Simulation
- [x] Verification was executed using a unified, self-checking testbench (`amtgc_top_tb.v`).
- [x] Automated assertions and scoreboards verified 39 distinct checks with zero failures.
- [x] Constrained-random stress testing was executed successfully over 1,000 cycles.
- [x] Waveform screenshots verifying normal cycling, emergency override, pedestrian arbitration, and adaptive timing are archived in `/sim`.

### 5. Final Compliance Declaration
I hereby attest that the code and documentation submitted in this repository represent my original work, have been thoroughly simulated and verified, and meet all professional engineering standards specified for this project.

**Author:** Aathira Vijay  
**Date:** October 18, 2026  
**Status:** Complete & Verified
