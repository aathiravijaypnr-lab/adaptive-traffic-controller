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
