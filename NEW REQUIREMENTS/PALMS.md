# PALMS v2.0 – Parallel Assembly Line Management System

## Document Purpose

This document is a consolidated business knowledge base of PALMS v2.0.

**Focus Areas**
- Factory workflow
- Business rules
- Sewing operations
- Attendance and stock management
- Efficiency and SAM policies
- Daily stock position
- Reports and alerts
- User responsibilities

**Excluded**
- Technology stack
- Frameworks
- Programming languages
- Deployment architecture
- Infrastructure details
- Implementation code

---

# 1. Introduction

PALMS (Parallel Assembly Line Management System) is a garment factory management system that manages the complete lifecycle of a shirt from:

```text
Cutting
↓
Sub Assembly
↓
Full Garment Assembly
↓
Finished Garments
↓
Washing
↓
Ironing Rough Press
↓
QC Verification
↓
Ironing Final Press
↓
Packing
↓
Ready To Market
↓
Dispatch
```

The system provides:

- Production tracking
- Operator efficiency
- WIP monitoring
- Daily stock position
- Attendance management
- Stock availability tracking
- Production loss analysis
- Pacemaker identification
- Method study workflow
- RTM reporting

---

# 2. Scope

PALMS covers:

### Sewing Operations

- 27 Sub Assembly operations
- Full Garment Assembly

### Post Sewing Stations

1. Finished Garments Station (FGS)
2. Washing Station
3. Ironing Rough Press
4. QC Verification
5. Ironing Final Press
6. Packing Station
7. Ready To Market

### Other Functional Areas

- Daily Stock Position
- Attendance
- Stock Availability
- SAM Management
- Efficiency Reporting
- Bottleneck Detection
- Production Loss Calculation
- Pacemaker Identification
- Method Study

---

# 3. Terminologies

| Term | Meaning |
|------|---------|
| SAM | Standard Allowed Minutes |
| PALMS | Parallel Assembly Line Management System |
| WIP | Work In Progress |
| OB | Operation Bulletin |
| PF&D | Personal Fatigue & Delay Allowance |
| FGS | Finished Garments Station |
| WSH | Washing Station |
| IRN-R | Ironing Rough Press |
| QCV | QC Verification |
| IRN-F | Ironing Final Press |
| PKG | Packing |
| RTM | Ready To Market |

---

# 4. Complete Factory Flow

## S1 – Sub Assembly

Contains:

### Preparation

- Cutting
- Fusing
- Washcare Label

### Collar Line

- Collar Run
- Edge Cutting
- Collar Bone Preparing
- Collar Top Stitch
- Collar Band Attach
- Collar Band Top Stitch
- Collar Middle

### Cuff Line

- Cuff Run
- Cuff Edge Cutting
- Cuff Hemming
- Collar Marking & Cuff Turn
- Top Stitch Cuff

### Back Body

- Back Main Label
- Back Yoke Adding
- Back Top Stitch

### Front Body

- Front Kansai Left Placket
- Front Right Patti
- Pocket Iron
- Pocket Hemming
- Pocket Attach

### Sleeve Line

- Sleeve Small Placket
- Sleeve Big Placket
- Sleeve Big Placket Iron
- Sleeve Small Placket Lock

---

## S2 – Full Garment Assembly

Operations:

- Collar Attach to Body
- Sleeve Attach
- Side Seam & Sleeve Closing
- Cuff Attach
- Bottom Hem
- Button & Buttonhole
- Thread Trimming & Inspection

---

## Post Sewing Flow

```text
S2
↓
FGS
↓
Washing
↓
Ironing Rough
↓
QC
↓
Ironing Final
↓
Packing
↓
RTM
↓
Dispatch
```

---

# 5. User Roles

## Factory Manager

Can:

- View all dashboards
- Approve stock positions
- Review RTM reports
- Monitor production

---

## Production Supervisor

Responsible for:

- Attendance
- Operator allocation
- WIP monitoring
- Stock updates
- Shift management
- Alert response

---

## IE / SAM Analyst

Responsible for:

- Operation Bulletin
- SAM updates
- Industry SAM
- Time Studies
- Method Studies
- Efficiency analysis

---

## Operator

Can:

- Scan bundles
- View own efficiency
- View piece count

---

## QC Inspector

Responsible for:

- Defect logging
- QC Verification
- Rework management

---

## Store Keeper

Responsible for:

- Packing stock
- RTM stock
- Dispatch entries
- Manual stock updates

---

# 6. Daily Stock Position Formula

Every station follows:

```text
Closing Balance

=

Opening Balance

+

Additions

-

Dispatched
```

---

# 7. Station Stock Tracking

## FGS

Tracks:

- Opening Balance
- Pieces Received
- Pieces Dispatched
- Closing Balance

Alert:

```text
Closing Balance > 50 pcs
```

---

## Washing

Tracks:

- Opening
- Received from FGS
- Sent to Ironing
- Closing

Additional:

- Wash cycles
- Batch size
- Cycle time
- Pieces washed

Alert:

```text
Closing Balance > 200 pcs
```

---

## Ironing Rough

Tracks:

- Opening
- From Washing
- To QC
- Closing

Alert:

```text
Closing Balance > 180 pcs
```

---

## QC

Tracks:

- Opening
- From Rough Iron
- To Final Iron
- Closing

Tracks:

- Defects
- Rework

Alert:

```text
Rework > 5%
```

---

## Ironing Final

Tracks:

- Opening
- From QC
- To Packing
- Closing

Alert:

```text
Closing Balance > 160 pcs
```

---

## Packing

Tracks:

- Opening
- From Final Press
- To RTM
- Closing

Packing Operations:

- Collar Stay & Tissue Insert
- Price Tag Attach
- Folding on Board
- Polybag Insertion
- Box Packing
- Carton Sealing

Tracks:

- Cartons packed
- Cartons sealed
- Pieces per carton

Alert:

```text
Critical Efficiency < 50%
```

---

## RTM

Tracks:

- Opening Stock
- Production Added
- Dispatched
- Closing Stock

Additional Details:

- Style
- Size
- Colour
- Order Number
- Buyer Name

RTM is cumulative.

Stock does NOT reset daily.

---

# 8. WIP Tracking

System tracks:

- Bundle barcode
- Current station
- Entry timestamp
- Exit timestamp

Tracks:

- Stage wise WIP
- Sub line WIP

Alert:

```text
Stage 2 WIP

>

2 Bundles Ahead
```

---

# 9. Bottleneck Detection

Rule:

```text
Highest SAM

=

Bottleneck
```

Current:

```text
Stage 2

SAM = 12.00

Throughput = 40 pcs/day

Status = BOTTLENECK
```

---

# 10. Efficiency Formula

```text
Efficiency %

=

Total SAM Earned

/

Time on Machine

×

100
```

---

# 11. Efficiency Classification

## Critical

```text
Efficiency < 50%
```

Action:

- Immediate intervention
- Method study
- Critical alert

Examples:

- Stn 37 : 10%
- Stn 36 : 18%
- Stn 38 : 33%
- Stn 13 : 48%

---

## Low

```text
50% - 84%
```

Action:

- Coaching
- Improvement Plan

---

## Marginal

```text
85% - 99%
```

Action:

- Monitor

---

## Good

```text
100% - 149%
```

Action:

- Maintain

---

## Excellent

```text
≥150%
```

Action:

- Pacemaker
- Trainer Candidate

Examples:

- Stn 9 : 276%
- Stn 14 : 233%
- Stn 28 : 217%

---

# 12. Attendance Management

Possible Status:

```text
PRESENT
ABSENT
REASSIGNED
```

If absent:

- Station marked Unmanned
- Dashboard alert

If Critical Station absent:

```text
CRITICAL ALERT
```

Attendance retained for:

```text
12 Months
```

---

# 13. Stock Availability

Before shift:

Every station marked:

```text
AVAILABLE

OR

NO STOCK
```

No Stock:

- Station marked Starved
- Supervisor Alert
- Logged with reason

---

# 14. Industry SAM

If Factory SAM unavailable:

Use:

```text
Industry SAM
```

Such stations:

- Tagged Pending Study
- Excluded from incentives
- Require:

```text
Minimum 30 Observations
```

before approval.

---

# 15. Pacemaker Identification

Rule:

```text
Efficiency

≥150%
```

Then:

- Add to Pacemaker Registry
- Trainer Candidate
- Recognition Eligible

Examples:

- U Durga – 275.9%
- Lakshmi Reddy – 232.6%
- E Kavya – 227.3%
- Masthan B – 217.4%

---

# 16. Method Study

Triggered when:

```text
Efficiency < 50%
```

Work Order:

Contains:

- Station
- Operator
- Efficiency
- Shift Date
- Status

Lifecycle:

```text
OPEN

↓

ASSIGNED

↓

IN PROGRESS

↓

CLOSED
```

---

# 17. Derived Actual Time

If observation unavailable:

```text
Actual Time

=

60

/

Actual Pieces Per Hour
```

Derived values:

- Marked as (D)
- Cannot update SAM
- Must be replaced within:

```text
5 Working Days
```

---

# 18. Production Loss

Formula:

```text
Shift Risk Score

=

Σ

480

/

SAM

for all

Absent Stations

+

No Stock Stations
```

Displayed:

- Dashboard Header
- Top 5 impact stations
- Daily trends

---

# 19. RTM Rules

RTM is:

- Final inventory checkpoint
- Dispatch ready stock

Tracks:

- Buyer wise stock
- Order wise stock
- Style wise stock

Daily:

Generate:

```text
RTM REPORT

17:00
```

Includes:

- Opening
- Added
- Dispatched
- Closing

Grouped by:

- Style
- Order
- Buyer

---

# 20. Reports

Standard Reports:

- Hourly Production
- Daily Efficiency
- SAM vs Actual
- Bottleneck Analysis
- QC Defect Summary
- Attendance Report
- No Stock Report
- Shift Risk Report
- RTM Report
- Daily Stock Position
- Pacemaker Report
- Method Study Report

Export:

- PDF
- Excel

---

# 21. Daily Stock Position Board

Tracks:

FGS

WSH

IRN-R

QCV

IRN-F

PKG

RTM

For every station:

- Opening Balance
- Additions
- Dispatched
- Closing Balance
- Maximum WIP
- Alerts
- Seven Day Trend

Real Time Updates:

- Barcode Scans
- Manual Entries

---

# 22. Complete Station Reference

| Zone | Station | Max Alert |
|------|---------|----------|
| S1 | Sub Assembly | Critical Path Absent |
| S2 | Full Garment Assembly | WIP > 2 Bundles |
| FGS | Finished Garments | >50 pcs |
| WSH | Washing | >200 pcs |
| IRN-R | Ironing Rough | >180 pcs |
| QCV | QC | Rework >5% |
| IRN-F | Ironing Final | >160 pcs |
| PKG | Packing | >240 pcs |
| RTM | Ready To Market | Below MOQ |

---

# Total System

```text
Total SAM

=

47.70 min/pc

Line Throughput

=

40 pcs/day

Governed by:

Stage 2 Bottleneck
```