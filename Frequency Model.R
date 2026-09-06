#Fit the Poisson Model
freq_model <- glm(
  ClaimNb ~ Area + VehPower + VehAge + DrivAge + BonusMalus + VehBrand + VehGas + Region,
  data    = freq_clean,
  family  = poisson(link = "log"),
  offset  = log(Exposure)
)

summary(freq_model)

freq %>%
  mutate(bm_band = cut(DrivAge, breaks = c(10, 20,30,40,50,60,70, 80, 100))) %>%
  group_by(bm_band) %>%
  summarise(avg_freq = sum(ClaimNb) / sum(Exposure), n = n()) %>%
  print()

#Using drivAge as a coefficient and banding to avaoid a linear review,
freq_clean <- freq_clean %>%
  mutate(DrivAge_band = cut(DrivAge, breaks = c(10, 20, 30, 40, 50, 60, 70, 80, 100), include.lowest = TRUE))

freq_model_v2 <- glm(
  ClaimNb ~ Area + VehPower + VehAge + DrivAge_band + BonusMalus + VehBrand + VehGas + Region,
  data    = freq_clean,
  family  = poisson(link = "log"),
  offset  = log(Exposure)
)

summary(freq_model_v2)
AIC(freq_model, freq_model_v2)


summary(freq_model_v2)$coefficients[grep("DrivAge_band", rownames(summary(freq_model_v2)$coefficients)), ]

