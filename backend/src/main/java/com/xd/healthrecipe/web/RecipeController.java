package com.xd.healthrecipe.web;

import com.xd.healthrecipe.domain.HealthGoal;
import com.xd.healthrecipe.domain.MealType;
import com.xd.healthrecipe.domain.Recipe;
import com.xd.healthrecipe.dto.ApiResponse;
import com.xd.healthrecipe.dto.RecipePage;
import com.xd.healthrecipe.repository.RecipeRepository;
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
    private final RecipeRepository recipeRepository;

    public RecipeController(RecipeCatalogService recipeCatalogService, RecipeRepository recipeRepository) {
        this.recipeCatalogService = recipeCatalogService;
        this.recipeRepository = recipeRepository;
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

    @GetMapping("/page")
    public ApiResponse<RecipePage> page(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "4") int size,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String mealType,
            @RequestParam(required = false, defaultValue = "default") String sort
    ) {
        int limit = Math.max(1, Math.min(size, 100));
        int offset = Math.max(0, (page - 1)) * limit;
        List<Recipe> data = recipeRepository.searchPaged(
                keyword == null || keyword.isBlank() ? null : keyword,
                mealType == null || mealType.isBlank() ? null : mealType,
                sort,
                limit,
                offset
        );
        int total = recipeRepository.countFiltered(keyword, mealType);
        int totalPages = (int) Math.ceil((double) total / limit);
        return ApiResponse.ok(new RecipePage(data, total, page, limit, totalPages));
    }
}
