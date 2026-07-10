package com.xd.healthrecipe.service;

import com.xd.healthrecipe.domain.Recipe;
import com.xd.healthrecipe.domain.UserAccount;
import com.xd.healthrecipe.dto.RecipeHistoryItem;
import com.xd.healthrecipe.dto.UserCenterSummary;
import com.xd.healthrecipe.repository.RecipeRepository;
import com.xd.healthrecipe.repository.UserRecipeRepository;
import com.xd.healthrecipe.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class UserCenterService {
    private final UserRepository userRepository;
    private final RecipeRepository recipeRepository;
    private final UserRecipeRepository userRecipeRepository;

    public UserCenterService(
            UserRepository userRepository,
            RecipeRepository recipeRepository,
            UserRecipeRepository userRecipeRepository
    ) {
        this.userRepository = userRepository;
        this.recipeRepository = recipeRepository;
        this.userRecipeRepository = userRecipeRepository;
    }

    public UserCenterSummary summary(String userId) {
        UserAccount account = requireUser(userId);
        List<Recipe> favorites = recipesByIds(userRecipeRepository.favoriteIds(userId));
        List<Recipe> recentHistory = recipesByIds(userRecipeRepository.recentHistoryIds(userId, 3));
        return new UserCenterSummary(
                account.id(),
                account.username(),
                account.displayName(),
                userRecipeRepository.favoriteCount(userId),
                userRecipeRepository.historyCount(userId),
                userRecipeRepository.syncEnabled(userId),
                favorites,
                recentHistory
        );
    }

    public List<Recipe> favorites(String userId) {
        requireUser(userId);
        return recipesByIds(userRecipeRepository.favoriteIds(userId));
    }

    public List<Recipe> addFavorite(String userId, String recipeId) {
        requireUser(userId);
        requireRecipe(recipeId);
        userRecipeRepository.addFavorite(userId, recipeId);
        return favorites(userId);
    }

    public List<Recipe> removeFavorite(String userId, String recipeId) {
        requireUser(userId);
        userRecipeRepository.removeFavorite(userId, recipeId);
        return favorites(userId);
    }

    public List<Recipe> addHistory(String userId, String recipeId) {
        requireUser(userId);
        requireRecipe(recipeId);
        userRecipeRepository.addHistory(userId, recipeId);
        return history(userId);
    }

    public List<RecipeHistoryItem> historyItems(String userId) {
        requireUser(userId);
        List<String[]> entries = userRecipeRepository.recentHistoryWithTime(userId, 99);
        List<RecipeHistoryItem> items = new ArrayList<>();
        for (String[] entry : entries) {
            recipeRepository.findById(entry[0]).ifPresent(recipe ->
                    items.add(new RecipeHistoryItem(recipe, entry[1]))
            );
        }
        return items;
    }

    public List<Recipe> history(String userId) {
        requireUser(userId);
        return recipesByIds(userRecipeRepository.recentHistoryIds(userId, 10));
    }

    public void clearHistory(String userId) {
        requireUser(userId);
        userRecipeRepository.clearHistory(userId);
    }

    public boolean updateSyncSetting(String userId, boolean syncEnabled) {
        requireUser(userId);
        userRecipeRepository.saveSyncEnabled(userId, syncEnabled);
        return syncEnabled;
    }

    private UserAccount requireUser(String userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User does not exist"));
    }

    private Recipe requireRecipe(String recipeId) {
        return recipeRepository.findById(recipeId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe does not exist"));
    }

    private List<Recipe> recipesByIds(List<String> recipeIds) {
        return recipeIds.stream()
                .map(recipeRepository::findById)
                .flatMap(java.util.Optional::stream)
                .toList();
    }
}
