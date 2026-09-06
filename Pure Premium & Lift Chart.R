
# Predicted claim frequency per policy (accounting for exposure via the offset)
freq_clean$pred_freq <- predict(freq_model_v2, newdata = freq_clean, type = "response")

# Predicted severity per policy — note we're predicting for EVERY policy here,
# not just ones that claimed, since we need an expected severity for pricing
freq_clean$pred_sev <- predict(sev_glm, newdata = freq_clean, type = "response")

# Combine into pure premium
freq_clean$pred_pure_premium <- freq_clean$pred_freq * freq_clean$pred_sev

summary(freq_clean$pred_pure_premium)

view(freq_clean)

freq_clean$pred_freq <- predict(freq_model_v2, newdata = freq_clean, type = "response")
freq_clean$pred_sev <- predict(sev_glm, newdata = freq_clean, type = "response")
freq_clean$pred_pure_premium <- freq_clean$pred_freq * freq_clean$pred_sev

summary(freq_clean$pred_pure_premium)

#Let's check our severity limitation by comparing the correlation of pure premium to sev & freq
cor(freq_clean$pred_pure_premium, freq_clean$pred_freq)
cor(freq_clean$pred_pure_premium, freq_clean$pred_sev)

#DrivAge has been a significant predictor in both(correlating both) so they seem equally correlated to premium cz of that
cor(freq_clean$pred_freq, freq_clean$pred_sev)
# 0.121 is very low so there is little correlation betwen freq and sev
#Let's check the spread on each factor
sd(freq_clean$pred_freq) / mean(freq_clean$pred_freq)
sd(freq_clean$pred_sev) / mean(freq_clean$pred_sev)
# freq has a larger spread hence having a higher effect on pred premium. 
#Boils down to the number of predictors btn freq and sev

#Lift Chart. Step 1: Calculate actual cost per policy
actual_cost <- sev %>%
  group_by(IDpol) %>%
  summarise(actual_claim_cost = sum(ClaimAmount))

freq_clean <- freq_clean %>%
  left_join(actual_cost, by = "IDpol") %>%
  mutate(actual_claim_cost = replace_na(actual_claim_cost, 0))
sum(freq_clean$actual_claim_cost > 0)

#Step 2: Rank every policy into 10 equal-sized risk groups
freq_clean <- freq_clean %>%
  mutate(risk_decile = ntile(pred_pure_premium, 10))

lift_table <- freq_clean %>%
  group_by(risk_decile) %>%
  summarise(
    avg_predicted = mean(pred_pure_premium),
    avg_actual    = mean(actual_claim_cost),
    n_policies    = n()
  )

print(lift_table)

# Two lines over the deciles: predicted vs actual. A well-calibrated model
# shows them tracking each other closely and both rising left to right.
ggplot(lift_table, aes(x = risk_decile)) +
  geom_line(aes(y = avg_predicted, color = "Predicted"), linewidth = 1) +
  geom_point(aes(y = avg_predicted, color = "Predicted"), size = 2) +
  geom_line(aes(y = avg_actual, color = "Actual"), linewidth = 1) +
  geom_point(aes(y = avg_actual, color = "Actual"), size = 2) +
  scale_x_continuous(breaks = 1:10) +
  labs(
    title = "Lift Chart: Predicted vs Actual Pure Premium by Risk Decile",
    x = "Risk Decile (1 = Lowest Predicted Risk, 10 = Highest)",
    y = "Average Pure Premium (EUR)",
    color = "Series"
  ) +
  theme_minimal()