package com.xd.healthrecipe.domain;

import java.util.List;

public record HealthAssessment(
        double bmi,
        String bmiLevel,
        NutritionTarget target,
        List<String> advices
) {
}
