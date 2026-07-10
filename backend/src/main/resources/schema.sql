CREATE TABLE IF NOT EXISTS user_account (
    id VARCHAR(64) PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    password VARCHAR(128) NOT NULL,
    display_name VARCHAR(64) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS health_profile (
    user_id VARCHAR(64) PRIMARY KEY,
    age INT NOT NULL,
    gender VARCHAR(20) NOT NULL,
    height_cm DECIMAL(6,2) NOT NULL,
    weight_kg DECIMAL(6,2) NOT NULL,
    goal VARCHAR(40) NOT NULL,
    chronic_conditions VARCHAR(255) NOT NULL DEFAULT '',
    taboos VARCHAR(255) NOT NULL DEFAULT '',
    taste_preferences VARCHAR(255) NOT NULL DEFAULT '',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS recipe (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    meal_type VARCHAR(20) NOT NULL,
    category VARCHAR(64) NOT NULL,
    suitable_goals VARCHAR(255) NOT NULL,
    tags VARCHAR(255) NOT NULL DEFAULT '',
    ingredients TEXT NOT NULL,
    steps TEXT NOT NULL,
    calories INT NOT NULL,
    protein_gram INT NOT NULL,
    fat_gram INT NOT NULL,
    carbohydrate_gram INT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS diet_record (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    food_name VARCHAR(128) NOT NULL,
    meal_type VARCHAR(20) NOT NULL,
    calories INT NOT NULL,
    protein_gram INT NOT NULL,
    fat_gram INT NOT NULL,
    carbohydrate_gram INT NOT NULL,
    eaten_at DATETIME NOT NULL,
    INDEX idx_diet_record_user_time (user_id, eaten_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS recipe_favorite (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(64) NOT NULL,
    recipe_id VARCHAR(64) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_recipe_favorite_user_recipe (user_id, recipe_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS recipe_history (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(64) NOT NULL,
    recipe_id VARCHAR(64) NOT NULL,
    visit_count INT NOT NULL DEFAULT 1,
    last_viewed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_recipe_history_user_recipe (user_id, recipe_id),
    INDEX idx_recipe_history_user_time (user_id, last_viewed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS user_sync_setting (
    user_id VARCHAR(64) PRIMARY KEY,
    sync_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE recipe ADD COLUMN difficulty VARCHAR(20) NOT NULL DEFAULT '简单';
ALTER TABLE recipe ADD COLUMN cook_time VARCHAR(20) NOT NULL DEFAULT '15分钟';
