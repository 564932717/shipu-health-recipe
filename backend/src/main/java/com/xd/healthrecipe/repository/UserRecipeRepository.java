package com.xd.healthrecipe.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class UserRecipeRepository {
    private final JdbcTemplate jdbcTemplate;

    public UserRecipeRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public void addFavorite(String userId, String recipeId) {
        jdbcTemplate.update("""
                        INSERT INTO recipe_favorite (user_id, recipe_id, created_at)
                        VALUES (?, ?, NOW())
                        ON DUPLICATE KEY UPDATE created_at = created_at
                        """,
                userId,
                recipeId);
    }

    public void removeFavorite(String userId, String recipeId) {
        jdbcTemplate.update("""
                        DELETE FROM recipe_favorite
                        WHERE user_id = ? AND recipe_id = ?
                        """,
                userId,
                recipeId);
    }

    public List<String> favoriteIds(String userId) {
        return jdbcTemplate.queryForList("""
                        SELECT recipe_id
                        FROM recipe_favorite
                        WHERE user_id = ?
                        ORDER BY created_at DESC, id DESC
                        """,
                String.class,
                userId);
    }

    public int favoriteCount(String userId) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recipe_favorite WHERE user_id = ?",
                Integer.class,
                userId);
        return count == null ? 0 : count;
    }

    public void addHistory(String userId, String recipeId) {
        jdbcTemplate.update("""
                        INSERT INTO recipe_history (user_id, recipe_id, visit_count, last_viewed_at)
                        VALUES (?, ?, 1, NOW())
                        ON DUPLICATE KEY UPDATE
                        visit_count = visit_count + 1,
                        last_viewed_at = NOW()
                        """,
                userId,
                recipeId);
    }

    public List<String> recentHistoryIds(String userId, int limit) {
        return jdbcTemplate.queryForList("""
                        SELECT recipe_id
                        FROM recipe_history
                        WHERE user_id = ?
                        ORDER BY last_viewed_at DESC
                        LIMIT ?
                        """,
                String.class,
                userId,
                Math.max(1, limit));
    }

    public int historyCount(String userId) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recipe_history WHERE user_id = ?",
                Integer.class,
                userId);
        return count == null ? 0 : count;
    }

    public boolean syncEnabled(String userId) {
        List<Boolean> values = jdbcTemplate.queryForList("""
                        SELECT sync_enabled
                        FROM user_sync_setting
                        WHERE user_id = ?
                        """,
                Boolean.class,
                userId);
        return values.isEmpty() || Boolean.TRUE.equals(values.get(0));
    }

    public void saveSyncEnabled(String userId, boolean syncEnabled) {
        jdbcTemplate.update("""
                        INSERT INTO user_sync_setting (user_id, sync_enabled, updated_at)
                        VALUES (?, ?, NOW())
                        ON DUPLICATE KEY UPDATE
                        sync_enabled = VALUES(sync_enabled),
                        updated_at = NOW()
                        """,
                userId,
                syncEnabled);
    }
}
