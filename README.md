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
