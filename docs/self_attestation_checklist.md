# AMTGC — Self-Attestation Checklist

This document serves as a formal self-verification declaration by the author, confirming that all functional requirements, coding standards, verification targets, and repository guidelines have been meticulously reviewed and fulfilled prior to final submission.

## Repository and documentation
- [x] Five RTL modules are present in `rtl/`.
- [x] The integrated testbench and two standalone testbenches are present in `tb/`.
- [x] Technical report, assumptions, bug log, self-attestation, and four diagrams are present in `docs/`.
- [x] Simulation log and four waveform PNG files are present in `sim/`.
- [x] The final repository tree and filenames match the assignment's exact prescribed layout.
- [x] The GitHub repository is publicly accessible without signing in.

## RTL and architecture
- [x] One `clk` domain is used; `rst_n` is active low, with asynchronous reset in controllers/timers/synchronizer and synchronous reset in the pedestrian arbiter.
- [x] Two instances of `junction_controller` use the same default timing parameters and different `IS_JUNCTION_B` settings.
- [x] Two independent 32-bit `generic_timer` instances are used in the top-level design.
- [x] Adaptive timing uses `MIN_GREEN_TIME`, `MAX_GREEN_TIME`, and `GREEN_EXTENSION` with density values 0–7.
- [x] Shared pedestrian arbitration uses readiness inputs and round-robin `turn` priority.
- [x] Emergency output masking and green-wave synchronization are implemented.

## Recorded verification
- [x] `sim/simulation_run.log` reports 39 PASS and 0 FAIL.
- [x] The integrated log records 1,000 randomized cycles with zero new invariant violations.
- [x] Screenshots cover normal operation, emergency, pedestrian requests, and adaptive timing.
- [x] All required screenshot filenames and demonstration-video specifications match the assignment.
- [x] The demonstration video opens and plays without login.
- [x] All mandatory submission form fields and links have been verified.



**Author:** Aathira Vijay
**Status:** Complete & Verified
