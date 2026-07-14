package com.xd.healthrecipe.service;

import com.xd.healthrecipe.domain.HealthGoal;
import com.xd.healthrecipe.domain.MealType;
import com.xd.healthrecipe.domain.Recipe;
import com.xd.healthrecipe.repository.RecipeRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;
import java.util.Optional;

@Service
public class RecipeCatalogService {
    private final RecipeRepository recipeRepository;

    public RecipeCatalogService(RecipeRepository recipeRepository) {
        this.recipeRepository = recipeRepository;
    }

    public List<Recipe> search(String keyword, HealthGoal goal, MealType mealType) {
        String normalizedKeyword = keyword == null ? "" : keyword.toLowerCase(Locale.ROOT).trim();
        return recipeRepository.all().stream()
                .filter(recipe -> goal == null || recipe.matchesGoal(goal))
                .filter(recipe -> mealType == null || recipe.mealType() == mealType)
                .filter(recipe -> normalizedKeyword.isBlank() || containsKeyword(recipe, normalizedKeyword))
                .toList();
    }

    public Optional<Recipe> findById(String id) {
        return recipeRepository.findById(id);
    }

    public List<Recipe> all() {
        return recipeRepository.all();
    }

    private boolean containsKeyword(Recipe recipe, String keyword) {
        return recipe.name().toLowerCase(Locale.ROOT).contains(keyword);
    }
}
