package com.xd.healthrecipe.service;

import com.xd.healthrecipe.domain.HealthAssessment;
import com.xd.healthrecipe.domain.HealthGoal;
import com.xd.healthrecipe.domain.HealthProfile;
import com.xd.healthrecipe.domain.MealPlan;
import com.xd.healthrecipe.domain.MealType;
import com.xd.healthrecipe.domain.NutritionTarget;
import com.xd.healthrecipe.domain.Recipe;
import com.xd.healthrecipe.repository.RecipeRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Random;

@Service
public class RecommendationService {
    private final HealthAssessmentService assessmentService;
    private final RecipeCatalogService recipeCatalogService;
    private final RecipeRepository recipeRepository;
    private final Random random = new Random();

    public RecommendationService(HealthAssessmentService assessmentService,
                                  RecipeCatalogService recipeCatalogService,
                                  RecipeRepository recipeRepository) {
        this.assessmentService = assessmentService;
        this.recipeCatalogService = recipeCatalogService;
        this.recipeRepository = recipeRepository;
    }

    public MealPlan recommend(HealthProfile profile) {
        HealthAssessment assessment = assessmentService.evaluate(profile);
        HealthGoal goal = profile.goal() == null ? HealthGoal.BALANCED : profile.goal();

        List<Recipe> breakfast = pickBreakfast(goal, profile);
        List<Recipe> lunch = pickLunch(goal, profile);
        List<Recipe> dinner = pickDinner(goal, profile);
        List<Recipe> snack = pickSnack(goal, profile);

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

    private List<Recipe> pickBreakfast(HealthGoal goal, HealthProfile profile) {
        List<Recipe> candidates = recipeRepository.findByGoal(goal, MealType.BREAKFAST);
        candidates = filterTaboos(candidates, profile);
        if (candidates.isEmpty()) {
            candidates = recipeRepository.findByGoal(HealthGoal.BALANCED, MealType.BREAKFAST);
            candidates = filterTaboos(candidates, profile);
        }
        candidates.sort(Comparator.comparingInt(Recipe::proteinGram).reversed());
        return pickRandom(candidates, 1);
    }

    private List<Recipe> pickLunch(HealthGoal goal, HealthProfile profile) {
        List<Recipe> candidates = recipeRepository.findByGoal(goal, MealType.LUNCH);
        candidates = filterTaboos(candidates, profile);
        if (candidates.isEmpty()) {
            candidates = recipeRepository.findByGoal(HealthGoal.BALANCED, MealType.LUNCH);
            candidates = filterTaboos(candidates, profile);
        }
        candidates.sort(Comparator.comparingInt(Recipe::calories).reversed());
        return pickRandom(candidates, 1);
    }

    private List<Recipe> pickDinner(HealthGoal goal, HealthProfile profile) {
        List<Recipe> candidates = recipeRepository.findByGoal(goal, MealType.DINNER);
        candidates = filterTaboos(candidates, profile);
        if (candidates.isEmpty()) {
            candidates = recipeRepository.findByGoal(HealthGoal.BALANCED, MealType.DINNER);
            candidates = filterTaboos(candidates, profile);
        }
        candidates.sort(Comparator.comparingInt(r -> r.fatGram()));
        return pickRandom(candidates, 1);
    }

    private List<Recipe> pickSnack(HealthGoal goal, HealthProfile profile) {
        List<Recipe> candidates = recipeRepository.findByGoal(goal, MealType.SNACK);
        candidates = filterTaboos(candidates, profile);
        if (candidates.isEmpty()) {
            candidates = recipeRepository.findByGoal(HealthGoal.BALANCED, MealType.SNACK);
            candidates = filterTaboos(candidates, profile);
        }
        candidates.sort(Comparator.comparingInt(Recipe::proteinGram).reversed());
        return pickRandom(candidates, 1);
    }

    private List<Recipe> filterTaboos(List<Recipe> recipes, HealthProfile profile) {
        return new ArrayList<>(recipes.stream()
                .filter(recipe -> !recipe.containsAny(profile.taboos()))
                .toList());
    }

    private List<Recipe> pickRandom(List<Recipe> list, int count) {
        if (list.isEmpty()) {
            return List.of();
        }
        Collections.shuffle(list, random);
        return list.stream().limit(count).toList();
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
