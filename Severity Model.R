# Merge claim amounts with policy characteristics
sev_model_data <- sev %>%
  inner_join(freq_clean, by = "IDpol")

# Sanity check: how many claim records actually matched a policy?
nrow(sev)
nrow(sev_model_data)

# Quick look
summary(sev_model_data$ClaimAmount)

#Introduce the Gamma model
sev_glm <- glm(
  ClaimAmount ~ Area + VehPower + VehAge + DrivAge_band + BonusMalus + VehBrand + VehGas + Region,
  data   = sev_model_data,
  family = Gamma(link = "log")
)

summary(sev_glm)