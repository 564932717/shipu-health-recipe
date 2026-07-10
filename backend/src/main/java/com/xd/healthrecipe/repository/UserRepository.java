package com.xd.healthrecipe.repository;

import com.xd.healthrecipe.domain.UserAccount;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class UserRepository {
    private final JdbcTemplate jdbcTemplate;

    private final RowMapper<UserAccount> rowMapper = (rs, rowNum) -> new UserAccount(
            rs.getString("id"),
            rs.getString("username"),
            rs.getString("password"),
            rs.getString("display_name"),
            rs.getTimestamp("created_at").toLocalDateTime()
    );

    public UserRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public UserAccount save(UserAccount account) {
        jdbcTemplate.update("""
                        INSERT INTO user_account (id, username, password, display_name, created_at)
                        VALUES (?, ?, ?, ?, ?)
                        ON DUPLICATE KEY UPDATE
                        password = VALUES(password),
                        display_name = VALUES(display_name)
                        """,
                account.id(),
                account.username(),
                account.password(),
                account.displayName(),
                account.createdAt());
        return account;
    }

    public Optional<UserAccount> findByUsername(String username) {
        List<UserAccount> users = jdbcTemplate.query("""
                        SELECT id, username, password, display_name, created_at
                        FROM user_account
                        WHERE username = ?
                        """,
                rowMapper,
                username);
        return users.stream().findFirst();
    }

    public Optional<UserAccount> findById(String id) {
        List<UserAccount> users = jdbcTemplate.query("""
                        SELECT id, username, password, display_name, created_at
                        FROM user_account
                        WHERE id = ?
                        """,
                rowMapper,
                id);
        return users.stream().findFirst();
    }

    public boolean existsByUsername(String username) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM user_account WHERE username = ?",
                Integer.class,
                username);
        return count != null && count > 0;
    }

    public void updatePassword(String id, String password) {
        jdbcTemplate.update("""
                        UPDATE user_account
                        SET password = ?
                        WHERE id = ?
                        """,
                password,
                id);
    }

    public void updateDisplayName(String id, String displayName) {
        jdbcTemplate.update("""
                        UPDATE user_account
                        SET display_name = ?
                        WHERE id = ?
                        """,
                displayName,
                id);
    }

    public void migrateUserIdToUsername(String oldId, String username) {
        jdbcTemplate.update("UPDATE health_profile SET user_id = ? WHERE user_id = ?", username, oldId);
        jdbcTemplate.update("UPDATE diet_record SET user_id = ? WHERE user_id = ?", username, oldId);
        jdbcTemplate.update("UPDATE recipe_favorite SET user_id = ? WHERE user_id = ?", username, oldId);
        jdbcTemplate.update("UPDATE recipe_history SET user_id = ? WHERE user_id = ?", username, oldId);
        jdbcTemplate.update("UPDATE user_sync_setting SET user_id = ? WHERE user_id = ?", username, oldId);
        jdbcTemplate.update("UPDATE user_account SET id = ? WHERE id = ?", username, oldId);
    }
}
