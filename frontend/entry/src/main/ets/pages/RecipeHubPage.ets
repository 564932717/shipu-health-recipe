import { HealthProfile, MealPlan, MealType, Recipe } from '../common/Models';
import { MockData } from '../common/MockData';
import { ApiClient } from '../services/ApiClient';

@Component
export struct RecipeHubPage {
  @State plan: MealPlan = MockData.mealPlan;
  @State recipes: Recipe[] = [];
  @State keyword: string = '';
  @State categoryIndex: number = 0;
  @State selectedRecipe: Recipe | null = null;
  @State favoriteIds: string[] = [];
  @State historyNames: string[] = [];
  @State message: string = '';

  aboutToAppear() {
    this.load();
  }

  async load() {
    const profile: HealthProfile = await ApiClient.getProfile(ApiClient.currentUserId);
    this.plan = await ApiClient.recommend(profile);
    await this.search();
    await this.loadUserRecipeState();
  }

  async search() {
    this.recipes = await ApiClient.searchRecipes(this.keyword, '', this.mealTypeValue());
    this.message = this.recipes.length === 0 ? '没有找到匹配食谱，可换个关键词试试' : '';
  }

  async loadUserRecipeState() {
    try {
      await this.refreshFavoriteState();
      await this.refreshHistoryState();
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '收藏与历史加载失败，请稍后重试';
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.hero()
        this.recommendSection()
        this.searchSection()
        this.detailSection()
        this.favoriteSection()
      }
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
    }
    .backgroundColor('#F4F7F1')
  }

  @Builder
  hero() {
    Column({ space: 8 }) {
      Text('食谱中心')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
      Text('AI 推荐、分类浏览、详情、收藏与历史记录集中管理')
        .fontSize(13)
        .fontColor('#657064')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  recommendSection() {
    Column({ space: 12 }) {
      Row() {
        Text('今日 AI 餐单')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .layoutWeight(1)
        Button('换一换')
          .height(34)
          .fontSize(13)
          .fontColor('#FFF6D5')
          .backgroundColor('#071725')
          .borderRadius(17)
          .onClick(async () => {
            await this.load();
          })
      }
      .width('100%')

      this.mealCard('早餐', this.plan.breakfast[0], '#F8DD77')
      this.mealCard('午餐', this.plan.lunch[0], '#A8D9A1')
      this.mealCard('晚餐', this.plan.dinner[0], '#93BFE8')
      this.mealCard('加餐', this.plan.snack[0], '#E7B4C8')

      Text(`预估摄入 ${this.plan.estimatedIntake.dailyCalories} 千卡 · ${this.plan.estimatedIntake.macroRatio}`)
        .fontSize(13)
        .fontColor('#405146')
        .padding(12)
        .backgroundColor('#EAF3E4')
        .borderRadius(10)
        .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  mealCard(title: string, recipe: Recipe, color: string) {
    Row({ space: 12 }) {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width(46)
        .height(46)
        .textAlign(TextAlign.Center)
        .backgroundColor(color)
        .borderRadius(12)

      Column({ space: 4 }) {
        Text(recipe.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
        Text(`${recipe.calories} 千卡 · 蛋白质 ${recipe.proteinGram}g · 碳水 ${recipe.carbohydrateGram}g`)
          .fontSize(12)
          .fontColor('#657064')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#F8FAF5')
    .borderRadius(12)
    .onClick(async () => {
      await this.openRecipe(recipe);
    })
  }

  @Builder
  searchSection() {
    Column({ space: 12 }) {
      Text('食谱库')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Row({ space: 8 }) {
        TextInput({ placeholder: '搜索鸡胸、燕麦、低盐...', text: $$this.keyword })
          .height(44)
          .layoutWeight(1)
          .fontSize(14)
          .backgroundColor('#F6F8F2')
          .borderRadius(14)
          .padding({ left: 14, right: 14 })
        Button('搜索')
          .height(44)
          .fontSize(14)
          .fontColor('#FFF6D5')
          .backgroundColor('#156B45')
          .borderRadius(14)
          .onClick(async () => {
            await this.search();
          })
      }
      .width('100%')

      Row({ space: 8 }) {
        this.filterButton('全部', 0)
        this.filterButton('早餐', 1)
        this.filterButton('午餐', 2)
        this.filterButton('晚餐', 3)
        this.filterButton('加餐', 4)
      }
      .width('100%')

      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(13)
          .fontColor('#8B5E22')
          .padding(12)
          .backgroundColor('#FFF4D5')
          .borderRadius(10)
          .width('100%')
      }

      ForEach(this.recipes, (recipe: Recipe) => {
        this.recipeRow(recipe)
      })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  filterButton(label: string, index: number) {
    Button(label)
      .height(32)
      .fontSize(12)
      .fontColor(this.categoryIndex === index ? '#FFF6D5' : '#405146')
      .backgroundColor(this.categoryIndex === index ? '#071725' : '#EEF4EA')
      .borderRadius(16)
      .onClick(async () => {
        this.categoryIndex = index;
        await this.search();
      })
  }

  @Builder
  recipeRow(recipe: Recipe) {
    Column({ space: 8 }) {
      Row() {
        Column({ space: 4 }) {
          Text(recipe.name)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#071725')
          Text(`${recipe.category} · ${recipe.calories} 千卡 · ${recipe.tags.join(' / ')}`)
            .fontSize(12)
            .fontColor('#657064')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button(this.isFavorite(recipe.id) ? '已收藏' : '收藏')
          .height(32)
          .fontSize(12)
          .fontColor(this.isFavorite(recipe.id) ? '#156B45' : '#071725')
          .backgroundColor(this.isFavorite(recipe.id) ? '#E8F4EC' : '#F4E8BA')
          .borderRadius(16)
          .onClick(async () => {
            await this.toggleFavorite(recipe.id);
          })
      }
      .width('100%')

      Text(`食材：${recipe.ingredients.join('、')}`)
        .fontSize(13)
        .fontColor('#405146')
        .width('100%')
    }
    .padding(13)
    .backgroundColor('#F8FAF5')
    .borderRadius(14)
    .width('100%')
    .onClick(async () => {
      await this.openRecipe(recipe);
    })
  }

  @Builder
  detailSection() {
    if (this.selectedRecipe != null) {
      Column({ space: 10 }) {
        Text('食谱详情')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .width('100%')
        Text(this.selectedRecipe.name)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#156B45')
          .width('100%')
        Text(`适用：${this.selectedRecipe.category} · ${this.selectedRecipe.tags.join('、')}`)
          .fontSize(13)
          .fontColor('#657064')
          .width('100%')
        this.nutritionLine('热量', this.selectedRecipe.calories, '千卡', '#F8DD77')
        this.nutritionLine('蛋白质', this.selectedRecipe.proteinGram, 'g', '#A8D9A1')
        this.nutritionLine('脂肪', this.selectedRecipe.fatGram, 'g', '#E7B4C8')
        this.nutritionLine('碳水', this.selectedRecipe.carbohydrateGram, 'g', '#93BFE8')
        Text(`制作步骤：${this.selectedRecipe.steps.join('；')}`)
          .fontSize(13)
          .fontColor('#405146')
          .lineHeight(20)
          .width('100%')
      }
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .width('100%')
    }
  }

  @Builder
  nutritionLine(label: string, value: number, unit: string, color: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#657064')
        .width(58)
      Row()
        .height(10)
        .layoutWeight(1)
        .backgroundColor(color)
        .borderRadius(5)
      Text(`${value}${unit}`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width(62)
        .textAlign(TextAlign.End)
    }
    .width('100%')
  }

  @Builder
  favoriteSection() {
    Column({ space: 8 }) {
      Text('收藏与历史')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')
      Text(this.favoriteIds.length === 0 ? '暂无收藏食谱' : `已收藏 ${this.favoriteIds.length} 道食谱`)
        .fontSize(13)
        .fontColor('#657064')
        .width('100%')
      Text(this.historyNames.length === 0 ? '暂无浏览历史' : `最近查看：${this.historyNames.join('、')}`)
        .fontSize(13)
        .fontColor('#657064')
        .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  private mealTypeValue(): MealType | undefined {
    if (this.categoryIndex === 1) {
      return MealType.BREAKFAST;
    }
    if (this.categoryIndex === 2) {
      return MealType.LUNCH;
    }
    if (this.categoryIndex === 3) {
      return MealType.DINNER;
    }
    if (this.categoryIndex === 4) {
      return MealType.SNACK;
    }
    return undefined;
  }

  private async openRecipe(recipe: Recipe) {
    this.selectedRecipe = recipe;
    this.mergeHistoryName(recipe.name);
    try {
      await ApiClient.addRecipeHistory(ApiClient.currentUserId, recipe.id);
      await this.refreshHistoryState();
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '浏览历史同步失败';
    }
  }

  private isFavorite(id: string): boolean {
    return this.favoriteIds.indexOf(id) >= 0;
  }

  private async toggleFavorite(id: string) {
    const previous = this.favoriteIds.slice();
    if (this.isFavorite(id)) {
      this.favoriteIds = this.favoriteIds.filter((item: string) => item !== id);
      try {
        await ApiClient.deleteFavoriteRecipe(ApiClient.currentUserId, id);
        await this.refreshFavoriteState();
      } catch (error) {
        this.favoriteIds = previous;
        this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '取消收藏失败';
      }
      return;
    }
    const next = this.favoriteIds.slice();
    next.push(id);
    this.favoriteIds = next;
    try {
      await ApiClient.addFavoriteRecipe(ApiClient.currentUserId, id);
      await this.refreshFavoriteState();
    } catch (error) {
      this.favoriteIds = previous;
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '收藏失败';
    }
  }

  private async refreshFavoriteState() {
    const favorites = await ApiClient.listFavoriteRecipes(ApiClient.currentUserId);
    this.favoriteIds = this.recipeIds(favorites);
  }

  private async refreshHistoryState() {
    const history = await ApiClient.listRecipeHistory(ApiClient.currentUserId);
    this.historyNames = this.recipeNames(history, 3);
  }

  private mergeHistoryName(name: string) {
    const history = this.historyNames.filter((item: string) => item !== name);
    history.unshift(name);
    this.historyNames = history.slice(0, 3);
  }

  private recipeIds(recipes: Recipe[]): string[] {
    const ids: string[] = [];
    recipes.forEach((recipe: Recipe) => {
      ids.push(recipe.id);
    });
    return ids;
  }

  private recipeNames(recipes: Recipe[], limit: number): string[] {
    const names: string[] = [];
    const count = recipes.length > limit ? limit : recipes.length;
    for (let index = 0; index < count; index++) {
      names.push(recipes[index].name);
    }
    return names;
  }
}
