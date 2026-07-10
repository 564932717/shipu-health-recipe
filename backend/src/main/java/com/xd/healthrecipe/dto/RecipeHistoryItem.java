package com.xd.healthrecipe.dto;

import com.xd.healthrecipe.domain.Recipe;

public record RecipeHistoryItem(Recipe recipe, String lastViewedAt) {
}
