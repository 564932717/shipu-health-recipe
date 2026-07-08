package com.xd.healthrecipe.repository;

import com.xd.healthrecipe.domain.HealthGoal;
import com.xd.healthrecipe.domain.MealType;
import com.xd.healthrecipe.domain.Recipe;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

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
            rs.getInt("carbohydrate_gram")
    );

    public RecipeRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Optional<Recipe> findById(String id) {
        List<Recipe> recipes = jdbcTemplate.query("""
                        SELECT id, name, meal_type, category, suitable_goals, tags, ingredients, steps,
                               calories, protein_gram, fat_gram, carbohydrate_gram
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
                       calories, protein_gram, fat_gram, carbohydrate_gram
                FROM recipe
                ORDER BY id
                """, rowMapper);
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
