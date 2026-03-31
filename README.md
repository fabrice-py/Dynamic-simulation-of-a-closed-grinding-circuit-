
# 🔧 Closed Circuit Grinding & Hydrocyclone Simulation (MATLAB / Simulink)

## 📌 Overview

This project implements a **dynamic simulation of a closed grinding circuit** using **MATLAB and Simulink**.

The system includes:

* A **grinding mill model** (dynamic behavior with breakage)
* A **hydrocyclone classifier**
* A **recycle loop (closed circuit)**
* **Particle Size Distribution (PSD) analysis**
* Computation of key metrics: **P50, P80, circulating load**

The objective is to understand and simulate:

* Grinding performance
* Classification efficiency
* Circuit stability and dynamics

---

## ⚙️ System Description

The simulated process is a **closed-loop grinding circuit**:

```
Fresh Feed → Mill → Hydrocyclone → Overflow (product)
                             ↓
                        Underflow (recycle)
                             ↓
                            Mill
```

### Components:

* **Mill Dynamic Block**

  * Breakage matrix
  * Time dynamics (τ)
  * Size reduction

* **Hydrocyclone Block**

  * Classification based on particle size
  * Separation into:

    * Overflow (fine product)
    * Underflow (coarse recycle)

* **Recycle Loop**

  * Controls circulating load
  * Impacts stability and efficiency

---

## 📊 Key Outputs

The simulation produces:

* Mill product PSD
* Overflow PSD (final product)
* Underflow PSD (recycle stream)
* **Cumulative PSD curves**
* **P50 and P80**
* **Circulating Load (CL)**
---

## 📈 Post-Processing (Important)

Simulink performs the simulation, but **MATLAB is used for analysis and visualization**.

Example:

```matlab
compare_mill_vs_overflow
```

This script generates:

* Cumulative PSD curves
* Comparison between:

  * Mill product
  * Hydrocyclone overflow

---

## 📊 Example Analysis

The key comparison is:

* **Mill Product vs Overflow**

Interpretation:

* If Overflow curve is shifted left → **finer product**
* If P80 decreases → **better grinding/classification performance**

---

## 🧠 Key Metrics

### 🔹 P50

Median particle size (50% passing)

### 🔹 P80

Industry standard for grinding performance

### 🔹 Circulating Load (CL)

[
CL = \frac{F_{recycle}}{F_{fresh}}
]

Indicates how much material is recirculating in the system.

---

## 🔬 Model Assumptions

* Discrete size classes (6 bins)
* Simplified breakage kinetics
* Idealized cyclone classification (based on d50)
* No slurry rheology effects (simplified)

---

## 🛠️ Technologies Used

* MATLAB
* Simulink
* Signal processing
* Numerical modeling

---

## 📄 License

Open for educational use.


