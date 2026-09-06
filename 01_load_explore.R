
library(tidyverse)

# ---- 1. Load the two datasets ----
freq <- read.csv("data/freMTPL2freq.csv", stringsAsFactors = FALSE)
sev  <- read.csv("data/freMTPL2sev.csv",  stringsAsFactors = FALSE)

cat("Frequency dataset:", nrow(freq), "policies,", ncol(freq), "columns\n")
cat("Severity dataset:", nrow(sev), "claim records,", ncol(sev), "columns\n\n")

# ---- 2. Look at the structure ----
str(freq)
cat("\n")
str(sev)

# ---- 3. What do the columns mean? ----
# IDpol       - unique policy ID
# ClaimNb     - number of claims made on this policy (our frequency target)
# Exposure    - fraction of the year the policy was active (e.g. 0.5 = 6 months)
# Area        - population density category of where the policyholder lives
# VehPower    - engine power rating of the vehicle
# VehAge      - age of the vehicle in years
# DrivAge     - age of the driver
# BonusMalus  - French no-claims discount/penalty score (lower = better driving history)
# VehBrand    - vehicle manufacturer (anonymised codes)
# VehGas      - diesel or regular petrol
# Density     - population density of the driver's area
# Region      - French administrative region

# sev has: IDpol (links back to freq) and ClaimAmount (severity target)

# ---- 4. Basic sanity checks ----
summary(freq$Exposure)     # should range between 0 and 1 (fraction of year)
summary(freq$ClaimNb)      # most policies should have 0 claims
summary(sev$ClaimAmount)   # claim amounts — expect a right-skewed distribution

cat("\n% of policies with at least one claim:",
    round(mean(freq$ClaimNb > 0) * 100, 2), "%\n")

# A very small number of policies have Exposure > 1 (data entry errors — a
# policy can't be observed for more than 1 year here) and a handful have an
# implausibly high ClaimNb. 
cat("\nPolicies with Exposure > 1:", sum(freq$Exposure > 1), "\n")
cat("Max ClaimNb observed:", max(freq$ClaimNb), "\n")

# ---- 6. Does claim frequency rise with BonusMalus? ----
# (BonusMalus is France's no-claims bonus/malus score — higher = worse history)
freq %>%
  mutate(bm_band = cut(BonusMalus, breaks = c(50, 60, 80, 100, 130, 350))) %>%
  group_by(bm_band) %>%
  summarise(avg_freq = sum(ClaimNb) / sum(Exposure), n = n()) %>%
  print()

# Cap Exposure at 1 (can't be insured for more than a full year)
freq_clean <- freq %>%
  mutate(Exposure = pmin(Exposure, 1))

# Cap ClaimNb at a sensible max — 4 claims/year is already extreme;
freq_clean <- freq_clean %>%
  mutate(ClaimNb = pmin(ClaimNb, 4))

# Turn the categorical columns into factors so glm() treats them correctly
freq_clean <- freq_clean %>%
  mutate(
    Area     = as.factor(Area),
    VehBrand = as.factor(VehBrand),
    VehGas   = as.factor(VehGas),
    Region   = as.factor(Region)
  )


summary(freq_clean$Exposure)
summary(freq_clean$ClaimNb)

