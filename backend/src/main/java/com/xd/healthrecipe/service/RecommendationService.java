package com.xd.healthrecipe.service;

import com.xd.healthrecipe.domain.HealthAssessment;
import com.xd.healthrecipe.domain.HealthGoal;
import com.xd.healthrecipe.domain.HealthProfile;
import com.xd.healthrecipe.domain.MealPlan;
import com.xd.healthrecipe.domain.MealType;
import com.xd.healthrecipe.domain.NutritionTarget;
import com.xd.healthrecipe.domain.Recipe;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RecommendationService {
    private final HealthAssessmentService assessmentService;
    private final RecipeCatalogService recipeCatalogService;

    public RecommendationService(HealthAssessmentService assessmentService, RecipeCatalogService recipeCatalogService) {
        this.assessmentService = assessmentService;
        this.recipeCatalogService = recipeCatalogService;
    }

    public MealPlan recommend(HealthProfile profile) {
        HealthAssessment assessment = assessmentService.evaluate(profile);
        HealthGoal goal = profile.goal() == null ? HealthGoal.BALANCED : profile.goal();
        List<Recipe> breakfast = pick(goal, MealType.BREAKFAST, profile);
        List<Recipe> lunch = pick(goal, MealType.LUNCH, profile);
        List<Recipe> dinner = pick(goal, MealType.DINNER, profile);
        List<Recipe> snack = pick(goal, MealType.SNACK, profile);
        NutritionTarget intake = sum(breakfast, lunch, dinner, snack);
        return new MealPlan(
                assessment,
                breakfast,
                lunch,
                dinner,
                snack,
                intake,
                List.of("推荐结果会根据目标、忌口、食谱标签进行过滤。", "后续可加入用户反馈权重，提高个性化程度。")
        );
    }

    private List<Recipe> pick(HealthGoal goal, MealType mealType, HealthProfile profile) {
        List<Recipe> filtered = recipeCatalogService.search(null, goal, mealType).stream()
                .filter(recipe -> !recipe.containsAny(profile.taboos()))
                .toList();
        if (filtered.isEmpty()) {
            filtered = recipeCatalogService.search(null, HealthGoal.BALANCED, mealType);
        }
        return filtered.stream().limit(1).toList();
    }

    @SafeVarargs
    private NutritionTarget sum(List<Recipe>... groups) {
        int calories = 0;
        int protein = 0;
        int fat = 0;
        int carbs = 0;
        for (List<Recipe> group : groups) {
            for (Recipe recipe : group) {
                calories += recipe.calories();
                protein += recipe.proteinGram();
                fat += recipe.fatGram();
                carbs += recipe.carbohydrateGram();
            }
        }
        String ratio = protein + "g 蛋白质 / " + fat + "g 脂肪 / " + carbs + "g 碳水";
        return new NutritionTarget(calories, protein, fat, carbs, ratio);
    }
}
