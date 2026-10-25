Cardiometabolic Risk & Hospital Stay Stratifier
"""Clinical Cardiometabolic & Hospital Stay Risk Engine.

Designed for Hospital Inpatient & Cath Lab Strategic Planning.
"""

from typing import Any, Dict


def calculate_bmi(weight_kg: float, height_cm: float) -> float:
    """Calculate Body Mass Index (BMI)."""
    if height_cm <= 0 or weight_kg <= 0:
        raise ValueError("Height and weight must be positive numbers.")
    height_m = height_cm / 100.0
    return round(weight_kg / (height_m**2), 2)


def evaluate_clinical_risk(
    bmi: float, has_cardiac_history: bool = False
) -> Dict[str, Any]:
    """Stratify patient risk, estimate impact on Length of Stay (LOS),

    and recommend clinical pathway for transformation & quality teams.
    """
    if bmi < 18.5:
        category = "Underweight"
        los_factor = "+1.2 Days (High frailty / malnutrition risk)"
        priority = "Moderate"
        pathway = "Clinical Nutrition Assessment & Frailty Screening"
    elif 18.5 <= bmi <= 24.9:
        category = "Normal weight"
        los_factor = "Baseline (Standard care pathway)"
        priority = "Routine"
        pathway = "Standard Clinical Care & Discharge Protocol"
    elif 25.0 <= bmi <= 29.9:
        category = "Overweight"
        los_factor = "+0.5 Days (Mild metabolic risk)"
        priority = "Low-Moderate"
        pathway = "Preventive Lifestyle Counseling & Outpatient Follow-up"
    elif 30.0 <= bmi <= 34.9:
        category = "Obesity Class I"
        los_factor = "+1.5 Days (Increased procedural & vascular risk)"
        priority = "High"
        pathway = (
            "Pre-Cath Lab Vascular Assessment & Early Ambulation Protocol"
        )
    elif 35.0 <= bmi <= 39.9:
        category = "Obesity Class II"
        los_factor = "+2.3 Days (Elevated wound, thromboembolic & ICU bed risk)"
        priority = "Critical"
        pathway = "Enhanced Recovery After Surgery (ERAS) & DVT Prophylaxis"
    else:
        category = "Obesity Class III (Severe / Morbid)"
        los_factor = (
            "+3.8 Days (Severe cardiopulmonary & readmission vulnerability)"
        )
        priority = "Urgent / High Resource Utilization"
        pathway = "Multidisciplinary Care Team (Cardio, Bariatric, ICU Liaison)"

    # Escalate risk if patient has concurrent cardiac history
    if has_cardiac_history and bmi >= 30.0:
        los_factor += " [Warning: Cardiac history adds +1.0 day bed buffer]"
        pathway += " + Targeted Heart Failure / Vascular Monitoring"

    return {
        "BMI": bmi,
        "WHO Category": category,
        "Strategic Resource Priority": priority,
        "Estimated Inpatient LOS Impact": los_factor,
        "Recommended Clinical Transformation Pathway": pathway,
    }


if __name__ == "__main__":
    print("=== Dallah Transformation & Clinical Strategy Simulation ===")
    sample_weight = 105.0  # kg
    sample_height = 172.0  # cm
    cardiac_history = True

    calculated_bmi = calculate_bmi(sample_weight, sample_height)
    results = evaluate_clinical_risk(
        calculated_bmi, has_cardiac_history=cardiac_history
    )

    print(f"Patient BMI: {results['BMI']} ({results['WHO Category']})")
    print(f"Resource Priority: {results['Strategic Resource Priority']}")
    print(f"Hospital LOS Impact: {results['Estimated Inpatient LOS Impact']}")
    print(f"Action Pathway: {results['Recommended Clinical Transformation Pathway']}")
