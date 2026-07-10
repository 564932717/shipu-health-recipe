import { HealthProfile, MealPlan, Recipe, RecipePageResponse } from '../common/Models';
import { MockData } from '../common/MockData';
import { ApiClient } from '../services/ApiClient';
import { SortSelector } from './SortSelector';
import router from '@ohos.router';

@Component
export struct RecipeHubPage {
  @State plan: MealPlan = MockData.mealPlan;
  @State recipes: Recipe[] = [];
  @State keyword: string = '';
  @State categoryIndex: number = 0;
  @StorageLink('favIds') favoriteIds: string[] = [];
  @State message: string = '';
  @State currentPage: number = 1;
  @State totalPages: number = 1;
  @State total: number = 0;
  @State @Watch('onSortChanged') sortType: string = 'default';
  @State isLoading: boolean = false;
  private pageSize: number = 4;

  aboutToAppear() {
    this.load();
  }

  async load() {
    const profile: HealthProfile = await ApiClient.getProfile(ApiClient.currentUserId);
    this.plan = await ApiClient.recommend(profile);
    await this.loadRecipes();
    await this.refreshFavoriteState();
  }

  onSortChanged() {
    this.currentPage = 1;
    this.loadRecipes();
  }

  async loadRecipes() {
    this.isLoading = true;
    const currentKeyword = this.keyword;
    const currentSortType = this.sortType;
    const currentMealType = this.mealTypeParam();
    try {
      const response: RecipePageResponse = await ApiClient.getRecipePage(
        this.currentPage,
        this.pageSize,
        currentKeyword,
        currentMealType,
        currentSortType
      );
      this.recipes = response.data;
      this.total = response.total;
      this.totalPages = response.totalPages;
      if (this.currentPage > this.totalPages) {
        this.currentPage = Math.max(1, this.totalPages);
      }
      this.message = this.recipes.length === 0 ? '没有找到匹配食谱，可换个关键词试试' : '';
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '食谱加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.hero()
        this.recommendSection()
        this.searchSection()
        this.sortSection()
        this.recipeListSection()
        this.paginationSection()
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
      Text('AI 推荐、分类浏览与详情，收藏管理请到「我的」页面')
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
            this.currentPage = 1;
            await this.loadRecipes();
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
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  sortSection() {
    SortSelector({ currentSort: this.sortType, onSortChange: (value: string) => {
      this.sortType = value;
    } })
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
        this.currentPage = 1;
        await this.loadRecipes();
      })
  }

  @Builder
  recipeListSection() {
    Column({ space: 12 }) {
      if (this.total > 0) {
        Text(`共 ${this.total} 道食谱 · 第 ${this.currentPage}/${this.totalPages} 页`)
          .fontSize(13)
          .fontColor('#657064')
          .width('100%')
      }

      if (this.isLoading) {
        LoadingProgress()
          .width(36)
          .height(36)
          .color('#156B45')
          .margin({ top: 12, bottom: 12 })
      }

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
        this.recipeCard(recipe)
      })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  recipeCard(recipe: Recipe) {
    Column({ space: 8 }) {
      Row() {
        Column({ space: 4 }) {
          Text(recipe.name)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#071725')
          Text(`${recipe.tags.join(' / ')}`)
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
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Row({ space: 8 }) {
        this.nutritionBadge('热量', recipe.calories, '千卡', '#F8DD77')
        this.nutritionBadge('蛋白质', recipe.proteinGram, 'g', '#A8D9A1')
        this.nutritionBadge('脂肪', recipe.fatGram, 'g', '#E7B4C8')
        this.nutritionBadge('碳水', recipe.carbohydrateGram, 'g', '#93BFE8')
      }

      Text(`食材：${recipe.ingredients.join('、')}`)
        .fontSize(13)
        .fontColor('#405146')
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
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
  nutritionBadge(label: string, value: number, unit: string, color: string) {
    Row({ space: 4 }) {
      Text(label)
        .fontSize(11)
        .fontColor('#657064')
      Text(`${value}${unit}`)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor(color)
    .borderRadius(8)
  }

  @Builder
  paginationSection() {
    Column() {
      if (this.totalPages > 1) {
        Row({ space: 4 }) {
          Button('上一页')
            .height(38)
            .fontSize(13)
            .fontColor(this.currentPage <= 1 ? '#B8C4B6' : '#405146')
            .backgroundColor(this.currentPage <= 1 ? '#F0F4ED' : '#EEF4EA')
            .borderRadius(19)
            .padding({ left: 14, right: 14 })
            .enabled(this.currentPage > 1 && !this.isLoading)
            .opacity(this.currentPage <= 1 ? 0.5 : 1.0)
            .onClick(async () => {
              if (this.currentPage > 1 && !this.isLoading) {
                this.currentPage--;
                await this.loadRecipes();
              }
            })

          ForEach(this.pageNumbers(), (num: number) => {
            Button(`${num}`)
              .height(38)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(num === this.currentPage ? '#FFF6D5' : '#405146')
              .backgroundColor(num === this.currentPage ? '#156B45' : Color.Transparent)
              .borderRadius(8)
              .padding({ left: 14, right: 14 })
              .enabled(!this.isLoading)
              .onClick(async () => {
                if (num !== this.currentPage && !this.isLoading) {
                  this.currentPage = num;
                  await this.loadRecipes();
                }
              })
          })

          Button('下一页')
            .height(38)
            .fontSize(13)
            .fontColor(this.currentPage >= this.totalPages ? '#B8C4B6' : '#405146')
            .backgroundColor(this.currentPage >= this.totalPages ? '#F0F4ED' : '#EEF4EA')
            .borderRadius(19)
            .padding({ left: 14, right: 14 })
            .enabled(this.currentPage < this.totalPages && !this.isLoading)
            .opacity(this.currentPage >= this.totalPages ? 0.5 : 1.0)
            .onClick(async () => {
              if (this.currentPage < this.totalPages && !this.isLoading) {
                this.currentPage++;
                await this.loadRecipes();
              }
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .padding({ top: 8, bottom: 8 })
      }
    }
    .width('100%')
  }

  private mealTypeParam(): string {
    if (this.categoryIndex === 1) {
      return 'BREAKFAST';
    }
    if (this.categoryIndex === 2) {
      return 'LUNCH';
    }
    if (this.categoryIndex === 3) {
      return 'DINNER';
    }
    if (this.categoryIndex === 4) {
      return 'SNACK';
    }
    return '';
  }

  private pageNumbers(): number[] {
    const pages: number[] = [];
    let start = Math.max(1, this.currentPage - 1);
    let end = Math.min(this.totalPages, start + 3);
    if (end - start < 3) {
      start = Math.max(1, end - 3);
    }
    for (let i = start; i <= end; i++) {
      pages.push(i);
    }
    return pages;
  }

  private async openRecipe(recipe: Recipe) {
    try {
      await ApiClient.addRecipeHistory(ApiClient.currentUserId, recipe.id);
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '浏览历史同步失败';
    }
    try {
      router.pushUrl({ url: 'pages/RecipeDetailPage', params: { recipeId: recipe.id } });
    } catch (_err) {
      this.message = '页面跳转失败';
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
    const ids: string[] = [];
    favorites.forEach((r: Recipe) => ids.push(r.id));
    AppStorage.setOrCreate('favIds', ids);
  }
}
