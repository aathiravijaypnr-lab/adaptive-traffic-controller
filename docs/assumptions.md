# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)
## System Assumptions & Design Boundaries

This document outlines the operational assumptions, timing bounds, parameter configurations, and hardware constraints established for the AMTGC system architecture.

---

## 1. Clocking & Reset Strategy
- **Single Clock Domain:** All synchronous sequential elements across all modules (`generic_timer`, `junction_controller`, `ped_arbiter`, `amtgc_top`) operate on a single global clock signal (`clk`). There are no asynchronous clock domain crossings (CDC) or multi-clock FIFOs required.
- **Synchronous Reset:** The system utilizes a synchronous active-low reset (`rst_n`). All FSM state registers and timer countdown values initialize safely to their default states on the active clock edge when `rst_n` is low.

---

## 2. Timing Parameter Configurations
To demonstrate true hardware reusability without modifying RTL source code, the two junctions are instantiated with the following default timing parameters:

| Parameter Name | Junction A Value | Junction B Value | Description |
| :--- | :--- | :--- | :--- |
| `GREEN_TIME` | 10 clock cycles | 8 clock cycles | Baseline green signal duration |
| `YELLOW_TIME` | 3 clock cycles | 3 clock cycles | Yellow clearance signal duration |
| `RED_TIME` | 2 clock cycles | 2 clock cycles | Minimum mandatory All-Red safety gap |
| `PED_TIME` | 5 clock cycles | 5 clock cycles | Pedestrian crosswalk walk phase duration |
| `COUNTER_WIDTH` | 8 bits | 8 bits | Bit-width for timer countdown registers (supports up to 255 cycles) |

---

## 3. Traffic-Adaptive Timing Boundaries
- **Density Range:** The `traffic_density` input is assumed to be a 3-bit unsigned integer ranging from `3'b000` (density 0) to `3'b111` (density 7).
- **Safety Bounds:** 
  - **Minimum Green Limit:** Even under zero traffic density (`0`), the green phase is guaranteed never to drop below `MIN_GREEN_TIME` (set to 5 cycles).
  - **Maximum Green Limit:** Even under maximum traffic density (`7`), the green phase is strictly capped at `MAX_GREEN_TIME` (set to 20 cycles) to prevent arterial gridlock and ensure regular phase rotation.
- **Sampling Window:** Traffic density is sampled precisely once per phase transition (at the entry of a green state) to prevent mid-count jitter or timer glitching.

---

## 4. Green-Wave Synchronization Link
- **Offset Mechanism:** Junction B's North-South green phase initiation is coupled to Junction A's North-South green phase start via a configured delay offset (`green_wave_sync`).
- **Bounded Tolerance:** The coordination link assumes an arterial propagation delay of 4 clock cycles, ensuring vehicle platoons pass through Junction B immediately as its green signal activates.

---

## 5. Emergency Override & Pedestrian Rules
- **Override Precedence:** The global `emergency_override` signal has absolute highest priority. Upon assertion, it immediately overrides all ongoing FSM states, disables pedestrian walks, and forces all junction lights into a safe All-Red state within $\le 2$ clock cycles.
- **Fairness Policy:** The shared `ped_arbiter` assumes a round-robin arbitration scheme with state history memory (`last_served`), ensuring that simultaneous pedestrian requests from both junctions alternate priority to guarantee zero starvation.
