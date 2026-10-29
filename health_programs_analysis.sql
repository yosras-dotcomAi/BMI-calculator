-- =====================================================================
-- Health Improvement Programs Analysis: SQL queries
-- Dataset: health_improvement_programs_data.csv (500 SYNTHETIC patient records)
-- Engine : SQLite (works in DB Browser for SQLite, DBeaver, or the sqlite3 CLI)
--
-- HOW TO LOAD (sqlite3 CLI):
--   sqlite3 hip.db
--   .mode csv
--   .import --skip 1 health_improvement_programs_data.csv patients_raw
--   .read health_programs_analysis.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. SETUP: typed table + clean blanks to NULL
--    (non-participants have no adherence or satisfaction score)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS patients;
CREATE TABLE patients AS
SELECT
    patient_id,
    CAST(age AS INTEGER)                              AS age,
    gender,
    department,
    program_participant,
    CAST(months_enrolled AS INTEGER)                  AS months_enrolled,
    CAST(baseline_bmi AS REAL)                        AS baseline_bmi,
    CAST(followup_bmi AS REAL)                        AS followup_bmi,
    CAST(baseline_systolic_bp AS REAL)                AS baseline_systolic_bp,
    CAST(followup_systolic_bp AS REAL)                AS followup_systolic_bp,
    CAST(baseline_hba1c AS REAL)                      AS baseline_hba1c,
    CAST(followup_hba1c AS REAL)                      AS followup_hba1c,
    CAST(baseline_ldl AS REAL)                        AS baseline_ldl,
    CAST(followup_ldl AS REAL)                        AS followup_ldl,
    CAST(NULLIF(program_adherence_pct, '') AS REAL)   AS program_adherence_pct,
    CAST(NULLIF(satisfaction_score_10, '') AS REAL)   AS satisfaction_score_10,
    CAST(readmitted_90d AS INTEGER)                   AS readmitted_90d
FROM patients_raw;

-- ---------------------------------------------------------------------
-- Q1. Data quality: row count, duplicate IDs, missing values
-- ---------------------------------------------------------------------
SELECT
    COUNT(*)                                                    AS total_rows,
    COUNT(DISTINCT patient_id)                                  AS unique_patients,
    COUNT(*) - COUNT(DISTINCT patient_id)                       AS duplicate_ids,
    SUM(CASE WHEN baseline_bmi IS NULL OR followup_bmi IS NULL THEN 1 ELSE 0 END) AS missing_bmi,
    SUM(CASE WHEN program_participant = 'Yes' AND program_adherence_pct IS NULL THEN 1 ELSE 0 END) AS participants_missing_adherence
FROM patients;

-- ---------------------------------------------------------------------
-- Q2. Group sizes and average age: participants vs comparison group
-- ---------------------------------------------------------------------
SELECT
    program_participant,
    COUNT(*)                       AS patients,
    ROUND(AVG(age), 1)             AS avg_age,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM patients), 1) AS pct_of_total
FROM patients
GROUP BY program_participant;

-- ---------------------------------------------------------------------
-- Q3. Average change from baseline to follow-up (4 clinical metrics) by group
-- ---------------------------------------------------------------------
SELECT
    program_participant,
    ROUND(AVG(followup_bmi - baseline_bmi), 2)                   AS avg_bmi_change,
    ROUND(AVG(followup_systolic_bp - baseline_systolic_bp), 2)   AS avg_systolic_change,
    ROUND(AVG(followup_hba1c - baseline_hba1c), 2)               AS avg_hba1c_change,
    ROUND(AVG(followup_ldl - baseline_ldl), 2)                   AS avg_ldl_change
FROM patients
GROUP BY program_participant;

-- ---------------------------------------------------------------------
-- Q4. 90-day readmission rate by group
-- ---------------------------------------------------------------------
SELECT
    program_participant,
    COUNT(*)                                   AS patients,
    SUM(readmitted_90d)                        AS readmitted,
    ROUND(100.0 * SUM(readmitted_90d) / COUNT(*), 1) AS readmission_rate_pct
FROM patients
GROUP BY program_participant;

-- ---------------------------------------------------------------------
-- Q5. Readmission rate by department and group (CASE + conditional aggregation)
-- ---------------------------------------------------------------------
SELECT
    department,
    ROUND(100.0 * SUM(CASE WHEN program_participant = 'Yes' THEN readmitted_90d END)
          / SUM(CASE WHEN program_participant = 'Yes' THEN 1 END), 1)  AS participants_readmit_pct,
    ROUND(100.0 * SUM(CASE WHEN program_participant = 'No' THEN readmitted_90d END)
          / SUM(CASE WHEN program_participant = 'No' THEN 1 END), 1)   AS non_participants_readmit_pct
FROM patients
GROUP BY department
ORDER BY department;

-- ---------------------------------------------------------------------
-- Q6. Readmission by age band (CASE) and group
-- ---------------------------------------------------------------------
SELECT
    CASE
        WHEN age < 40 THEN '1. Under 40'
        WHEN age BETWEEN 40 AND 59 THEN '2. 40-59'
        WHEN age BETWEEN 60 AND 74 THEN '3. 60-74'
        ELSE '4. 75+'
    END AS age_band,
    program_participant,
    COUNT(*)                                          AS patients,
    ROUND(100.0 * SUM(readmitted_90d) / COUNT(*), 1)  AS readmission_rate_pct
FROM patients
GROUP BY age_band, program_participant
ORDER BY age_band, program_participant;

-- ---------------------------------------------------------------------
-- Q7. Does adherence matter? Adherence tiers among participants (CTE)
-- ---------------------------------------------------------------------
WITH tiers AS (
    SELECT *,
        CASE
            WHEN program_adherence_pct >= 80 THEN 'High (80%+)'
            WHEN program_adherence_pct >= 60 THEN 'Medium (60-79%)'
            ELSE 'Low (<60%)'
        END AS adherence_tier
    FROM patients
    WHERE program_participant = 'Yes'
)
SELECT
    adherence_tier,
    COUNT(*)                                          AS patients,
    ROUND(AVG(followup_hba1c - baseline_hba1c), 2)    AS avg_hba1c_change,
    ROUND(AVG(followup_systolic_bp - baseline_systolic_bp), 2) AS avg_systolic_change,
    ROUND(100.0 * SUM(readmitted_90d) / COUNT(*), 1)  AS readmission_rate_pct
FROM tiers
GROUP BY adherence_tier
ORDER BY adherence_tier;

-- ---------------------------------------------------------------------
-- Q8. Window function: rank departments by HbA1c improvement (participants only)
-- ---------------------------------------------------------------------
WITH dept AS (
    SELECT
        department,
        COUNT(*)                                        AS participants,
        AVG(followup_hba1c - baseline_hba1c)            AS avg_hba1c_change
    FROM patients
    WHERE program_participant = 'Yes'
    GROUP BY department
)
SELECT
    RANK() OVER (ORDER BY avg_hba1c_change ASC) AS improvement_rank,
    department,
    participants,
    ROUND(avg_hba1c_change, 2)                  AS avg_hba1c_change
FROM dept
ORDER BY improvement_rank;

-- ---------------------------------------------------------------------
-- Q9. Poorly controlled diabetes at baseline (HbA1c >= 8): how many reached
--     below 7 at follow-up, by group?
-- ---------------------------------------------------------------------
SELECT
    program_participant,
    COUNT(*)                                                       AS high_risk_patients,
    SUM(CASE WHEN followup_hba1c < 7 THEN 1 ELSE 0 END)            AS reached_target,
    ROUND(100.0 * SUM(CASE WHEN followup_hba1c < 7 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_reached_target
FROM patients
WHERE baseline_hba1c >= 8
GROUP BY program_participant;

-- ---------------------------------------------------------------------
-- Q10. Join a department summary back to the overall rate: which departments
--      have readmission above the hospital-wide average? (CTE + JOIN)
-- ---------------------------------------------------------------------
WITH overall AS (
    SELECT 100.0 * SUM(readmitted_90d) / COUNT(*) AS overall_rate FROM patients
),
dept AS (
    SELECT department,
           COUNT(*) AS patients,
           100.0 * SUM(readmitted_90d) / COUNT(*) AS dept_rate
    FROM patients
    GROUP BY department
)
SELECT
    d.department,
    d.patients,
    ROUND(d.dept_rate, 1)                         AS dept_readmission_pct,
    ROUND(o.overall_rate, 1)                      AS overall_readmission_pct,
    ROUND(d.dept_rate - o.overall_rate, 1)        AS gap_vs_overall
FROM dept d
JOIN overall o ON 1 = 1
ORDER BY gap_vs_overall DESC;
