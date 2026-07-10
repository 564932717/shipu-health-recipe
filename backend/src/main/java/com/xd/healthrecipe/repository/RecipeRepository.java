package com.xd.healthrecipe.repository;

import com.xd.healthrecipe.domain.HealthGoal;
import com.xd.healthrecipe.domain.MealType;
import com.xd.healthrecipe.domain.Recipe;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Repository
public class RecipeRepository {
    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<Recipe> rowMapper = (rs, rowNum) -> new Recipe(
            rs.getString("id"),
            rs.getString("name"),
            MealType.valueOf(rs.getString("meal_type")),
            rs.getString("category"),
            parseGoals(rs.getString("suitable_goals")),
            split(rs.getString("tags")),
            split(rs.getString("ingredients")),
            split(rs.getString("steps")),
            rs.getInt("calories"),
            rs.getInt("protein_gram"),
            rs.getInt("fat_gram"),
            rs.getInt("carbohydrate_gram"),
            rs.getString("difficulty"),
            rs.getString("cook_time")
    );

    public RecipeRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Optional<Recipe> findById(String id) {
        List<Recipe> recipes = jdbcTemplate.query("""
                        SELECT id, name, meal_type, category, suitable_goals, tags, ingredients, steps,
                               calories, protein_gram, fat_gram, carbohydrate_gram, difficulty, cook_time
                        FROM recipe
                        WHERE id = ?
                        """,
                rowMapper,
                id);
        return recipes.stream().findFirst();
    }

    public List<Recipe> all() {
        return jdbcTemplate.query("""
                SELECT id, name, meal_type, category, suitable_goals, tags, ingredients, steps,
                       calories, protein_gram, fat_gram, carbohydrate_gram, difficulty, cook_time
                FROM recipe
                ORDER BY id
                """, rowMapper);
    }

    public List<Recipe> findByGoal(HealthGoal goal, MealType mealType) {
        return jdbcTemplate.query("""
                SELECT id, name, meal_type, category, suitable_goals, tags, ingredients, steps,
                       calories, protein_gram, fat_gram, carbohydrate_gram, difficulty, cook_time
                FROM recipe
                WHERE (FIND_IN_SET('BALANCED', suitable_goals) > 0 OR FIND_IN_SET(?, suitable_goals) > 0)
                  AND meal_type = ?
                ORDER BY id
                """, rowMapper, goal.name(), mealType.name());
    }

    public List<Recipe> searchPaged(String keyword, String mealType, String sort, int limit, int offset) {
        StringBuilder sql = new StringBuilder("""
                SELECT id, name, meal_type, category, suitable_goals, tags, ingredients, steps,
                       calories, protein_gram, fat_gram, carbohydrate_gram, difficulty, cook_time
                FROM recipe
                WHERE 1=1
                """);
        List<Object> params = new ArrayList<>();

        if (mealType != null && !mealType.isBlank()) {
            sql.append(" AND meal_type = ?");
            params.add(mealType);
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND LOWER(name) LIKE ?");
            String like = "%" + keyword.toLowerCase() + "%";
            params.add(like);
        }

        sql.append(" ORDER BY ");
        switch (sort == null ? "" : sort) {
            case "calories_asc" -> sql.append("calories ASC");
            case "calories_desc" -> sql.append("calories DESC");
            case "protein_desc" -> sql.append("protein_gram DESC");
            case "fat_asc" -> sql.append("fat_gram ASC");
            case "carbohydrate_asc" -> sql.append("carbohydrate_gram ASC");
            default -> sql.append("id DESC");
        }

        sql.append(" LIMIT ? OFFSET ?");
        params.add(limit);
        params.add(offset);

        return jdbcTemplate.query(sql.toString(), rowMapper, params.toArray());
    }

    public int countFiltered(String keyword, String mealType) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM recipe WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (mealType != null && !mealType.isBlank()) {
            sql.append(" AND meal_type = ?");
            params.add(mealType);
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND LOWER(name) LIKE ?");
            String like = "%" + keyword.toLowerCase() + "%";
            params.add(like);
        }

        Integer count = jdbcTemplate.queryForObject(sql.toString(), Integer.class, params.toArray());
        return count == null ? 0 : count;
    }

    private static List<String> split(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        return Arrays.stream(value.split(","))
                .map(String::trim)
                .filter(item -> !item.isBlank())
                .toList();
    }

    private static Set<HealthGoal> parseGoals(String value) {
        EnumSet<HealthGoal> goals = EnumSet.noneOf(HealthGoal.class);
        for (String item : split(value)) {
            goals.add(HealthGoal.valueOf(item));
        }
        if (goals.isEmpty()) {
            goals.add(HealthGoal.BALANCED);
        }
        return goals;
    }
}
