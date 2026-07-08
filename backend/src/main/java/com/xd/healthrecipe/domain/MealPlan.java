package com.xd.healthrecipe.domain;

import java.util.List;

public record MealPlan(
        HealthAssessment assessment,
        List<Recipe> breakfast,
        List<Recipe> lunch,
        List<Recipe> dinner,
        List<Recipe> snack,
        NutritionTarget estimatedIntake,
        List<String> notes
) {
}
