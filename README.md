# Claims Pricing Model — Two-Part GLM (Frequency × Severity)

**Author:** Gabriel Kokonya
**Tools:** R (`glm`, `tidyverse`)
**Dataset:** freMTPL2freq / freMTPL2sev — French motor third-party liability insurance (678,013 policies, 26,639 claim records)

## Summary

This project replicates the standard actuarial approach to pricing a motor insurance policy: a **two-part Generalized Linear Model (GLM)** estimating claim frequency and claim severity separately, then combining them into a pure premium. It follows the methodology taught in actuarial exams and used in real insurance pricing teams.

**Pure Premium = Expected Frequency × Expected Severity**

## Method

1. **Frequency model** — Poisson GLM (log link) predicting number of claims per policy, using `log(Exposure)` as an offset to fairly compare policies observed for different durations.
2. **Severity model** — Gamma GLM (log link) predicting claim amount given a claim occurred, fitted only on policies with actual claims.
3. **Pure premium** — the two models' predictions multiplied together, per policy.
4. **Validation** — a lift chart comparing predicted vs. actual average cost across 10 risk deciles, the standard actuarial sense-check for whether a pricing model actually discriminates between low- and high-risk policies.

## Key Findings

- **Claim frequency** is well explained by policy characteristics: `BonusMalus` (France's no-claims score), `Area` (population density), `VehAge`, and `DrivAge` are all strong, highly significant predictors. Only 5.02% of policies had any claim in the observed period.
- **Driver age has a non-linear effect on frequency** — risk drops sharply after the youngest band (10–20) and then plateaus; a raw linear term mis-estimates this, so `DrivAge` was banded into 8 groups, which reduced AIC despite the added parameters.
- **Claim severity is far harder to predict from policy characteristics** — only `DrivAge_band` was clearly significant; `BonusMalus`, `Area`, `VehPower`, `VehAge`, and most `Region`/`VehBrand` levels were not. Claim size appears driven more by the specific circumstances of an accident than by who the driver is or where they live.
- **Young drivers carry a compounded risk** — they show both higher claim frequency *and* higher claim severity, independently, in both models.
- **The combined pure premium model successfully rank-orders risk**: actual average claims cost rises monotonically from €29.50 (lowest predicted decile) to €293 (highest predicted decile).
- **Calibration weakens in the highest-risk deciles** — predicted pure premium (€419 in the top decile) rises faster than actual (€293), suggesting the model overstates risk at the top end, likely reflecting the severity model's limited predictive power. A production model would benefit from recalibration (e.g. via a scaling correction or a richer severity model) before live use.

## Files

| File | Purpose |
|---|---|
| `01_load_explore.R` | Load both datasets, check structure, sanity-check ranges, identify data quality issues |
| `02_frequency_model.R` | Clean data, band DrivAge, fit the Poisson frequency GLM |
| `03_severity_model.R` | Merge claims to policy data, fit the Gamma severity GLM |
| `04_pure_premium_lift_chart.R` | Generate predictions, combine into pure premium, validate with a lift chart |
| `lift_chart.png` | Output validation chart |

## Limitations & Next Steps

- No interaction terms tested (e.g. whether the age effect on frequency varies by area).
- Poisson dispersion (mean = variance) was assumed, not formally tested for overdispersion.
- Model evaluated in-sample; a held-out test set would give a more honest measure of predictive performance.
- Severity's weak predictor set suggests potentially missing variables (e.g. claim-type or accident-circumstance data) not available in this dataset.
