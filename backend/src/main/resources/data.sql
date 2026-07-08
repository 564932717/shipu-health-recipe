INSERT INTO user_account (id, username, password, display_name, created_at)
VALUES ('demo-user', 'demo', '123456', '演示用户', NOW())
ON DUPLICATE KEY UPDATE password = VALUES(password), display_name = VALUES(display_name);

INSERT INTO health_profile
(user_id, age, gender, height_cm, weight_kg, goal, chronic_conditions, taboos, taste_preferences, updated_at)
VALUES
('demo-user', 22, 'MALE', 175, 72, 'FAT_LOSS', '轻度高血压', '花生,高盐', '清淡,高蛋白', NOW())
ON DUPLICATE KEY UPDATE
age = VALUES(age),
gender = VALUES(gender),
height_cm = VALUES(height_cm),
weight_kg = VALUES(weight_kg),
goal = VALUES(goal),
chronic_conditions = VALUES(chronic_conditions),
taboos = VALUES(taboos),
taste_preferences = VALUES(taste_preferences),
updated_at = NOW();

INSERT INTO recipe
(id, name, meal_type, category, suitable_goals, tags, ingredients, steps, calories, protein_gram, fat_gram, carbohydrate_gram)
VALUES
('B001', '燕麦鸡蛋牛奶早餐', 'BREAKFAST', '高蛋白早餐', 'FAT_LOSS,MUSCLE_GAIN,BALANCED', '高蛋白,低油,快手', '燕麦,鸡蛋,低脂牛奶,蓝莓', '燕麦加入低脂牛奶煮软,鸡蛋水煮 8 分钟,搭配少量蓝莓', 420, 28, 12, 48),
('B002', '全麦鸡胸三明治', 'BREAKFAST', '轻食早餐', 'FAT_LOSS,BALANCED', '低脂,饱腹', '全麦面包,鸡胸肉,生菜,番茄', '鸡胸肉煎熟切片,全麦面包夹入蔬菜和鸡胸肉', 360, 32, 8, 42),
('L001', '糙米鸡胸蔬菜碗', 'LUNCH', '减脂午餐', 'FAT_LOSS,BALANCED', '低脂,高纤维,控糖友好', '糙米,鸡胸肉,西兰花,胡萝卜', '糙米提前浸泡后蒸熟,鸡胸肉少油煎熟,蔬菜焯水后装盘', 560, 42, 14, 66),
('L002', '牛肉藜麦能量碗', 'LUNCH', '增肌午餐', 'MUSCLE_GAIN,BALANCED', '高蛋白,增肌,复合碳水', '瘦牛肉,藜麦,玉米,菠菜', '藜麦煮熟,瘦牛肉煎熟切片,与蔬菜组合装盘', 680, 48, 20, 78),
('D001', '清蒸鱼配杂粮饭', 'DINNER', '控压晚餐', 'BLOOD_PRESSURE_CONTROL,BALANCED', '低盐,优质蛋白,清淡', '鲈鱼,杂粮饭,芦笋,姜片', '鲈鱼加姜片清蒸,搭配杂粮饭和焯水芦笋', 520, 38, 13, 60),
('D002', '豆腐菌菇青菜汤', 'DINNER', '控糖晚餐', 'BLOOD_SUGAR_CONTROL,FAT_LOSS,BALANCED', '低碳,高纤维,清淡', '豆腐,香菇,青菜,海带', '菌菇煮出鲜味,加入豆腐和青菜煮熟,少盐调味', 310, 24, 12, 28),
('S001', '无糖酸奶坚果杯', 'SNACK', '健康加餐', 'FAT_LOSS,MUSCLE_GAIN,BALANCED', '加餐,高蛋白', '无糖酸奶,杏仁,奇亚籽', '酸奶倒入杯中,撒入坚果和奇亚籽', 220, 14, 12, 16)
ON DUPLICATE KEY UPDATE
name = VALUES(name),
meal_type = VALUES(meal_type),
category = VALUES(category),
suitable_goals = VALUES(suitable_goals),
tags = VALUES(tags),
ingredients = VALUES(ingredients),
steps = VALUES(steps),
calories = VALUES(calories),
protein_gram = VALUES(protein_gram),
fat_gram = VALUES(fat_gram),
carbohydrate_gram = VALUES(carbohydrate_gram);

INSERT INTO diet_record
(id, user_id, food_name, meal_type, calories, protein_gram, fat_gram, carbohydrate_gram, eaten_at)
VALUES
('demo-record-breakfast', 'demo-user', '燕麦鸡蛋牛奶早餐', 'BREAKFAST', 420, 28, 12, 48, NOW() - INTERVAL 8 HOUR),
('demo-record-lunch', 'demo-user', '糙米鸡胸蔬菜碗', 'LUNCH', 560, 42, 14, 66, NOW() - INTERVAL 3 HOUR),
('demo-record-dinner', 'demo-user', '清蒸鱼配杂粮饭', 'DINNER', 520, 38, 13, 60, NOW() - INTERVAL 1 DAY),
('demo-record-snack', 'demo-user', '无糖酸奶坚果杯', 'SNACK', 220, 14, 12, 16, NOW() - INTERVAL 2 DAY)
ON DUPLICATE KEY UPDATE
food_name = VALUES(food_name),
meal_type = VALUES(meal_type),
calories = VALUES(calories),
protein_gram = VALUES(protein_gram),
fat_gram = VALUES(fat_gram),
carbohydrate_gram = VALUES(carbohydrate_gram),
eaten_at = VALUES(eaten_at);

INSERT INTO recipe_favorite (user_id, recipe_id, created_at)
VALUES ('demo-user', 'B001', NOW())
ON DUPLICATE KEY UPDATE created_at = created_at;

INSERT INTO recipe_history (user_id, recipe_id, visit_count, last_viewed_at)
VALUES ('demo-user', 'B001', 1, NOW())
ON DUPLICATE KEY UPDATE
visit_count = recipe_history.visit_count + 1,
last_viewed_at = NOW();

INSERT INTO user_sync_setting (user_id, sync_enabled, updated_at)
VALUES ('demo-user', TRUE, NOW())
ON DUPLICATE KEY UPDATE
sync_enabled = VALUES(sync_enabled),
updated_at = NOW();
