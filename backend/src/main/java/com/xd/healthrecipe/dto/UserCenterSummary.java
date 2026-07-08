package com.xd.healthrecipe.dto;

import com.xd.healthrecipe.domain.Recipe;

import java.util.List;

public record UserCenterSummary(
        String userId,
        String username,
        String displayName,
        int favoriteCount,
        int historyCount,
        boolean syncEnabled,
        List<Recipe> favoriteRecipes,
        List<Recipe> recentHistory
) {
}
