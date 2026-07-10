package com.xd.healthrecipe.web;

import com.xd.healthrecipe.dto.ApiResponse;
import com.xd.healthrecipe.dto.ChangePasswordRequest;
import com.xd.healthrecipe.dto.LoginRequest;
import com.xd.healthrecipe.dto.RecipeHistoryItem;
import com.xd.healthrecipe.dto.RegisterRequest;
import com.xd.healthrecipe.dto.SyncSettingRequest;
import com.xd.healthrecipe.dto.UserCenterSummary;
import com.xd.healthrecipe.dto.UpdateProfileRequest;
import com.xd.healthrecipe.dto.UserSession;
import com.xd.healthrecipe.domain.Recipe;
import com.xd.healthrecipe.service.UserCenterService;
import com.xd.healthrecipe.service.UserService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService userService;
    private final UserCenterService userCenterService;

    public UserController(UserService userService, UserCenterService userCenterService) {
        this.userService = userService;
        this.userCenterService = userCenterService;
    }

    @PostMapping("/register")
    public ApiResponse<UserSession> register(@Valid @RequestBody RegisterRequest request) {
        return ApiResponse.ok(userService.register(request));
    }

    @PostMapping("/login")
    public ApiResponse<UserSession> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok(userService.login(request));
    }

    @PostMapping("/password")
    public ApiResponse<Void> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        userService.changePassword(request);
        return ApiResponse.ok(null);
    }

    @PutMapping("/{userId}/profile")
    public ApiResponse<UserSession> updateProfile(
            @PathVariable String userId,
            @Valid @RequestBody UpdateProfileRequest request
    ) {
        return ApiResponse.ok(userService.updateDisplayName(userId, request.displayName()));
    }

    @GetMapping("/{userId}/center")
    public ApiResponse<UserCenterSummary> center(@PathVariable String userId) {
        return ApiResponse.ok(userCenterService.summary(userId));
    }

    @GetMapping("/{userId}/favorites")
    public ApiResponse<List<Recipe>> favorites(@PathVariable String userId) {
        return ApiResponse.ok(userCenterService.favorites(userId));
    }

    @PostMapping("/{userId}/favorites/{recipeId}")
    public ApiResponse<List<Recipe>> addFavorite(@PathVariable String userId, @PathVariable String recipeId) {
        return ApiResponse.ok(userCenterService.addFavorite(userId, recipeId));
    }

    @DeleteMapping("/{userId}/favorites/{recipeId}")
    public ApiResponse<List<Recipe>> removeFavorite(@PathVariable String userId, @PathVariable String recipeId) {
        return ApiResponse.ok(userCenterService.removeFavorite(userId, recipeId));
    }

    @GetMapping("/{userId}/recipe-history")
    public ApiResponse<List<RecipeHistoryItem>> history(@PathVariable String userId) {
        return ApiResponse.ok(userCenterService.historyItems(userId));
    }

    @PostMapping("/{userId}/recipe-history/{recipeId}")
    public ApiResponse<List<RecipeHistoryItem>> addHistory(@PathVariable String userId, @PathVariable String recipeId) {
        userCenterService.addHistory(userId, recipeId);
        return ApiResponse.ok(userCenterService.historyItems(userId));
    }

    @DeleteMapping("/{userId}/recipe-history")
    public ApiResponse<Void> clearHistory(@PathVariable String userId) {
        userCenterService.clearHistory(userId);
        return ApiResponse.ok(null);
    }

    @PostMapping("/{userId}/sync-setting")
    public ApiResponse<Boolean> updateSyncSetting(
            @PathVariable String userId,
            @RequestBody SyncSettingRequest request
    ) {
        return ApiResponse.ok(userCenterService.updateSyncSetting(userId, request.syncEnabled()));
    }
}
