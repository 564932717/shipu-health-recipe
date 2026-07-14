export enum Gender {
  MALE = 'MALE',
  FEMALE = 'FEMALE',
  UNKNOWN = 'UNKNOWN'
}

export enum HealthGoal {
  FAT_LOSS = 'FAT_LOSS',
  MUSCLE_GAIN = 'MUSCLE_GAIN',
  BLOOD_SUGAR_CONTROL = 'BLOOD_SUGAR_CONTROL',
  BLOOD_PRESSURE_CONTROL = 'BLOOD_PRESSURE_CONTROL',
  BALANCED = 'BALANCED'
}

export enum MealType {
  BREAKFAST = 'BREAKFAST',
  LUNCH = 'LUNCH',
  DINNER = 'DINNER',
  SNACK = 'SNACK'
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  password: string;
  displayName: string;
}

export interface ChangePasswordRequest {
  userId: string;
  oldPassword: string;
  newPassword: string;
  confirmPassword: string;
}

export interface SyncSettingRequest {
  syncEnabled: boolean;
}

export interface UserSession {
  userId: string;
  username: string;
  displayName: string;
}

export interface HealthProfile {
  userId: string;
  age: number;
  gender: Gender;
  heightCm: number;
  weightKg: number;
  goal: HealthGoal;
  chronicConditions: string[];
  taboos: string[];
  tastePreferences: string[];
}

export interface NutritionTarget {
  dailyCalories: number;
  proteinGram: number;
  fatGram: number;
  carbohydrateGram: number;
  macroRatio: string;
}

export interface HealthAssessment {
  bmi: number;
  bmiLevel: string;
  target: NutritionTarget;
  advices: string[];
}

export interface Recipe {
  id: string;
  name: string;
  mealType: MealType;
  category: string;
  tags: string[];
  ingredients: string[];
  steps: string[];
  calories: number;
  proteinGram: number;
  fatGram: number;
  carbohydrateGram: number;
  difficulty: string;
  cookTime: string;
}

export interface RecipePageResponse {
  data: Recipe[];
  total: number;
  page: number;
  size: number;
  totalPages: number;
}

export interface RecipeHistoryItem {
  recipe: Recipe;
  lastViewedAt: string;
}

export interface MealPlan {
  assessment: HealthAssessment;
  breakfast: Recipe[];
  lunch: Recipe[];
  dinner: Recipe[];
  snack: Recipe[];
  estimatedIntake: NutritionTarget;
  notes: string[];
}

export interface DietRecord {
  id: string;
  userId: string;
  foodName: string;
  mealType: MealType;
  calories: number;
  proteinGram: number;
  fatGram: number;
  carbohydrateGram: number;
  eatenAt: string;
}

export interface DietRecordRequest {
  userId: string;
  foodName: string;
  mealType: MealType;
  calories: number;
  proteinGram: number;
  fatGram: number;
  carbohydrateGram: number;
  eatenAt?: string;
}

export interface NutritionSummary {
  userId: string;
  totalCalories: number;
  totalProteinGram: number;
  totalFatGram: number;
  totalCarbohydrateGram: number;
  calorieCompletion: number;
  suggestions: string[];
}

export interface UserCenterSummary {
  userId: string;
  displayName: string;
  favoriteCount: number;
  historyCount: number;
  syncEnabled: boolean;
  todayCalories: number;
  targetCalories: number;
  recommendedRecipeName: string;
}

export interface WeeklyReport {
  userId: string;
  startDate: string;
  endDate: string;
  averageCalories: number;
  recordDays: number;
  completionLevel: string;
  trendHighlights: string[];
  aiSuggestions: string[];
  dailyCalories: Record<string, number>;
  dailyProtein: Record<string, number>;
  dailyFat: Record<string, number>;
  dailyCarbs: Record<string, number>;
  avgProtein: number;
  avgFat: number;
  avgCarbs: number;
  calorieCompletionRate: number;
  proteinCompletionRate: number;
  fatCompletionRate: number;
  carbCompletionRate: number;
  recordDayRate: number;
  breakfastCount: number;
  lunchCount: number;
  dinnerCount: number;
  snackCount: number;
  weekOverWeekCalorieChange: number;
  weekOverWeekTrend: string;
  weeklyRecords: DietRecord[];
}

export interface UpdateProfileRequest {
  userId: string;
  displayName: string;
}

// AI 请求体
export interface AiRecommendMealsRequest {
  profile: HealthProfile;
  refreshIndex: number;
}

export interface AiWeeklySuggestionsRequest {
  userId: string;
  targetCalories: number;
  date: string;
}

export interface AiDailyAnalysisRequest {
  userId: string;
  date: string;
  targetCalories: number;
  targetProtein: number;
  targetFat: number;
  targetCarbs: number;
}

// AI 生成的食谱（不依赖数据库，由大模型实时生成）
export interface AiRecipe {
  name: string;
  calories: number;
  proteinGram: number;
  fatGram: number;
  carbohydrateGram: number;
  ingredients: string[];
  steps: string[];
  difficulty: string;
  cookTime: string;
}

// AI 生成的三餐方案
export interface AiMealPlan {
  breakfast: AiRecipe[];
  lunch: AiRecipe[];
  dinner: AiRecipe[];
  snack: AiRecipe[];
  estimatedIntake: NutritionTarget;
  notes: string[];
}
