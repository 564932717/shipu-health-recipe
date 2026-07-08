package com.xd.healthrecipe.web;

import com.xd.healthrecipe.domain.HealthGoal;
import com.xd.healthrecipe.domain.MealType;
import com.xd.healthrecipe.domain.Recipe;
import com.xd.healthrecipe.dto.ApiResponse;
import com.xd.healthrecipe.service.RecipeCatalogService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/recipes")
public class RecipeController {
    private final RecipeCatalogService recipeCatalogService;

    public RecipeController(RecipeCatalogService recipeCatalogService) {
        this.recipeCatalogService = recipeCatalogService;
    }

    @GetMapping
    public ApiResponse<List<Recipe>> search(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) HealthGoal goal,
            @RequestParam(required = false) MealType mealType
    ) {
        return ApiResponse.ok(recipeCatalogService.search(keyword, goal, mealType));
    }

    @GetMapping("/{id}")
    public ApiResponse<Recipe> detail(@PathVariable String id) {
        Recipe recipe = recipeCatalogService.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("食谱不存在"));
        return ApiResponse.ok(recipe);
    }
}
