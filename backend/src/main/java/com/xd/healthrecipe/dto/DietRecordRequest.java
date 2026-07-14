package com.xd.healthrecipe.dto;

import com.xd.healthrecipe.domain.MealType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record DietRecordRequest(
        @NotBlank String userId,
        @NotBlank String foodName,
        @NotNull MealType mealType,
        int calories,
        int proteinGram,
        int fatGram,
        int carbohydrateGram,
        String eatenAt
) {
}
