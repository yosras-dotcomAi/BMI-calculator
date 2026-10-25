# 🏥 Cardiometabolic Risk & Hospital Stay Stratifier (CRSS)
**Bridging Bedside Clinical Metrics with Hospital Resource Planning & Transformation Strategy**

---

## 📌 Executive Summary
In inpatient care and interventional suites (such as the Cardiac Catheterization Laboratory), patient body habitus directly influences post-procedural recovery, access-site complications, and total **Length of Stay (LOS)**. 

This repository provides an automated clinical decision-support and stratification logic built in **Python**. It transforms raw anthropometric measurements into actionable clinical risk tiers, allowing healthcare leaders and transformation units to:
- Predict and manage bed-turnover bottlenecks.
- Mitigate unbudgeted inpatient days.
- Deploy preventive, multi-disciplinary pathways before discharge.

---

## 🎯 Key Strategic & Operational Objectives
1. **Reduce Excess Bed Days:** Anticipate prolonged stays (+1.2 to +3.8 days) associated with extreme BMI classes.
2. **Prevent Readmissions:** Route high-risk cardiac and post-op patients into structured discharge protocols.
3. **Resource Allocation:** Enable nurse managers and bed coordinators to allocate nursing intensity dynamically based on patient acuity.

---

## ⚙️ Architecture & Logic
The engine classifies patients based on **WHO International Standards**, supplemented with clinical escalation flags:

| BMI Range (kg/m²) | Classification | Operational Priority | Projected LOS Variance | Recommended Action Pathway |
| :--- | :--- | :--- | :--- | :--- |
| `< 18.5` | Underweight | Moderate | +1.2 Days | Nutritional & Frailty Assessment |
| `18.5 – 24.9` | Normal | Routine | Baseline | Standard Discharge Pathway |
| `25.0 – 29.9` | Overweight | Low-Moderate | +0.5 Days | Lifestyle Counseling & Outpatient Care |
| `30.0 – 34.9` | Obesity Class I | High | +1.5 Days | Vascular / Pre-Cath Site Protocol |
| `35.0 – 39.9` | Obesity Class II | Critical | +2.3 Days | ERAS & Thromboembolic Prophylaxis |
| `≥ 40.0` | Obesity Class III | Urgent | +3.8 Days | Multidisciplinary ICU / Bariatric Liaison |

---

## 🚀 How to Run

1. Clone repository:
   ```bash
   git clone [https://github.com/yosras-dotcomAi/BMI-calculator.git](https://github.com/yosras-dotcomAi/BMI-calculator.git)
   cd BMI-calculator
