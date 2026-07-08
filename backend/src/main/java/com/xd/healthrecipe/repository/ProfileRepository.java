package com.xd.healthrecipe.repository;

import com.xd.healthrecipe.domain.Gender;
import com.xd.healthrecipe.domain.HealthGoal;
import com.xd.healthrecipe.domain.HealthProfile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

@Repository
public class ProfileRepository {
    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<HealthProfile> rowMapper = (rs, rowNum) -> new HealthProfile(
            rs.getString("user_id"),
            rs.getInt("age"),
            Gender.valueOf(rs.getString("gender")),
            rs.getDouble("height_cm"),
            rs.getDouble("weight_kg"),
            HealthGoal.valueOf(rs.getString("goal")),
            split(rs.getString("chronic_conditions")),
            split(rs.getString("taboos")),
            split(rs.getString("taste_preferences"))
    );

    public ProfileRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public HealthProfile save(HealthProfile profile) {
        jdbcTemplate.update("""
                        INSERT INTO health_profile
                        (user_id, age, gender, height_cm, weight_kg, goal, chronic_conditions, taboos, taste_preferences, updated_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
                        ON DUPLICATE KEY UPDATE
                        age = VALUES(age),
                        gender = VALUES(gender),
                        height_cm = VALUES(height_cm),
                        weight_kg = VALUES(weight_kg),
                        goal = VALUES(goal),
                        chronic_conditions = VALUES(chronic_conditions),
                        taboos = VALUES(taboos),
                        taste_preferences = VALUES(taste_preferences),
                        updated_at = NOW()
                        """,
                profile.userId(),
                profile.age(),
                valueOrDefault(profile.gender(), Gender.UNKNOWN).name(),
                profile.heightCm(),
                profile.weightKg(),
                valueOrDefault(profile.goal(), HealthGoal.BALANCED).name(),
                join(profile.chronicConditions()),
                join(profile.taboos()),
                join(profile.tastePreferences()));
        return profile;
    }

    public Optional<HealthProfile> find(String userId) {
        List<HealthProfile> profiles = jdbcTemplate.query("""
                        SELECT user_id, age, gender, height_cm, weight_kg, goal, chronic_conditions, taboos, taste_preferences
                        FROM health_profile
                        WHERE user_id = ?
                        """,
                rowMapper,
                userId);
        return profiles.stream().findFirst();
    }

    public List<HealthProfile> all() {
        return jdbcTemplate.query("""
                SELECT user_id, age, gender, height_cm, weight_kg, goal, chronic_conditions, taboos, taste_preferences
                FROM health_profile
                ORDER BY updated_at DESC
                """, rowMapper);
    }

    private static String join(List<String> values) {
        return String.join(",", values == null ? List.of() : values);
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

    private static <T> T valueOrDefault(T value, T defaultValue) {
        return value == null ? defaultValue : value;
    }
}
