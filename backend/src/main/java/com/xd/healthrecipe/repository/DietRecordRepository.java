package com.xd.healthrecipe.repository;

import com.xd.healthrecipe.domain.DietRecord;
import com.xd.healthrecipe.domain.MealType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.util.List;

@Repository
public class DietRecordRepository {
    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<DietRecord> rowMapper = (rs, rowNum) -> new DietRecord(
            rs.getString("id"),
            rs.getString("user_id"),
            rs.getString("food_name"),
            MealType.valueOf(rs.getString("meal_type")),
            rs.getInt("calories"),
            rs.getInt("protein_gram"),
            rs.getInt("fat_gram"),
            rs.getInt("carbohydrate_gram"),
            rs.getTimestamp("eaten_at").toLocalDateTime()
    );

    public DietRecordRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public DietRecord save(DietRecord record) {
        jdbcTemplate.update("""
                        INSERT INTO diet_record
                        (id, user_id, food_name, meal_type, calories, protein_gram, fat_gram, carbohydrate_gram, eaten_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                record.id(),
                record.userId(),
                record.foodName(),
                record.mealType().name(),
                record.calories(),
                record.proteinGram(),
                record.fatGram(),
                record.carbohydrateGram(),
                Timestamp.valueOf(record.eatenAt()));
        return record;
    }

    public List<DietRecord> listByUser(String userId) {
        return jdbcTemplate.query("""
                        SELECT id, user_id, food_name, meal_type, calories, protein_gram, fat_gram, carbohydrate_gram, eaten_at
                        FROM diet_record
                        WHERE user_id = ?
                        ORDER BY eaten_at DESC
                        """,
                rowMapper,
                userId);
    }
}
