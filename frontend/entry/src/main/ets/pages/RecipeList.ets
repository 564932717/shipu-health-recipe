import { Recipe, RecipePageResponse } from '../common/Models';
import { ApiClient } from '../services/ApiClient';
import router from '@ohos.router';

@Entry
@Component
export struct RecipeList {
  @State recipes: Recipe[] = [];
  @State currentPage: number = 1;
  @State totalPages: number = 1;
  @State total: number = 0;
  @State isLoading: boolean = false;
  @State favoriteIds: string[] = [];
  @State activeTab: number = 2;
  private pageSize: number = 9;

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const response: RecipePageResponse = await ApiClient.getRecipePage(
        this.currentPage,
        this.pageSize
      );
      this.recipes = response.data;
      this.total = response.total;
      this.totalPages = response.totalPages;
    } catch (error) {
      this.recipes = [];
    } finally {
      this.isLoading = false;
      this.loadFavoriteIds();
    }
  }

  async loadFavoriteIds() {
    try {
      const favorites = await ApiClient.listFavoriteRecipes(ApiClient.currentUserId);
      this.favoriteIds = [];
      for (let i = 0; i < favorites.length; i++) {
        this.favoriteIds.push(favorites[i].id);
      }
    } catch (error) {
      // silent
    }
  }

  async toggleFavorite(recipeId: string) {
    const idx = this.favoriteIds.indexOf(recipeId);
    if (idx >= 0) {
      this.favoriteIds.splice(idx, 1);
      try {
        await ApiClient.deleteFavoriteRecipe(ApiClient.currentUserId, recipeId);
      } catch (error) {
        this.favoriteIds.push(recipeId);
      }
    } else {
      this.favoriteIds.push(recipeId);
      try {
        await ApiClient.addFavoriteRecipe(ApiClient.currentUserId, recipeId);
      } catch (error) {
        const ri = this.favoriteIds.indexOf(recipeId);
        if (ri >= 0) {
          this.favoriteIds.splice(ri, 1);
        }
      }
    }
  }

  isFavorite(id: string): boolean {
    return this.favoriteIds.indexOf(id) >= 0;
  }

  async goPage(page: number) {
    if (page < 1 || page > this.totalPages || page === this.currentPage || this.isLoading) {
      return;
    }
    this.currentPage = page;
    await this.loadData();
  }

  pageNumbers(): number[] {
    const pages: number[] = [];
    const start = Math.max(1, this.currentPage - 2);
    const end = Math.min(this.totalPages, start + 4);
    const adjustedStart = Math.max(1, end - 4);
    for (let i = adjustedStart; i <= end; i++) {
      pages.push(i);
    }
    return pages;
  }

  build() {
    Column() {
      this.headerBar()
      this.listArea()
      this.paginationBar()
      this.bottomTabs()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F3EE')
  }

  @Builder
  headerBar() {
    Row() {
      Text(`共${this.total}道食谱 · 第${this.currentPage}/${this.totalPages}页`)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#4A4A4A')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ top: 16, bottom: 12 })
    .backgroundColor('#F5F3EE')
  }

  @Builder
  listArea() {
    if (this.isLoading) {
      Column() {
        LoadingProgress()
          .width(40)
          .height(40)
          .color('#156B45')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List() {
        ForEach(this.recipes, (recipe: Recipe) => {
          ListItem() {
            this.recipeCard(recipe)
          }
          .margin({ left: 12, right: 12, top: 8, bottom: 8 })
        })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
    }
  }

  @Builder
  recipeCard(recipe: Recipe) {
    Column({ space: 10 }) {
      Row() {
        Text(recipe.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button(this.isFavorite(recipe.id) ? '已收藏' : '收藏')
          .height(30)
          .fontSize(12)
          .fontColor(this.isFavorite(recipe.id) ? '#156B45' : '#7A6B4F')
          .backgroundColor(this.isFavorite(recipe.id) ? '#E0F0E4' : '#F4E8BA')
          .borderRadius(15)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            this.toggleFavorite(recipe.id);
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(recipe.tags.join(' · '))
        .fontSize(11)
        .fontColor('#9B9B9B')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Row() {
        this.nutritionItem('热量', recipe.calories, '千卡', '#F8DD77')
        this.nutritionItem('蛋白质', recipe.proteinGram, 'g', '#A8D9A1')
        this.nutritionItem('脂肪', recipe.fatGram, 'g', '#F0A0A0')
        this.nutritionItem('碳水', recipe.carbohydrateGram, 'g', '#93BFE8')
      }
      .width('100%')

      Text(recipe.ingredients.join('、'))
        .fontSize(12)
        .fontColor('#7A7A7A')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor('#FEF9F0')
    .borderRadius(16)
    .width('100%')
    .onClick(() => {
      router.pushUrl({ url: 'pages/RecipeDetailPage', params: { recipeId: recipe.id } });
    })
  }

  @Builder
  nutritionItem(label: string, value: number, unit: string, color: string) {
    Column({ space: 2 }) {
      Text(`${value}${unit}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Text(label)
        .fontSize(10)
        .fontColor('#9B9B9B')
    }
    .padding({ top: 8, bottom: 8 })
    .backgroundColor(color)
    .borderRadius(8)
    .layoutWeight(1)
    .margin({ left: 3, right: 3 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  paginationBar() {
    Row() {
      Button('上一页')
        .height(36)
        .fontSize(13)
        .fontColor(this.currentPage <= 1 ? '#C0C0C0' : '#4A4A4A')
        .backgroundColor('#00000000')
        .borderRadius(18)
        .enabled(this.currentPage > 1 && !this.isLoading)
        .opacity(this.currentPage <= 1 ? 0.4 : 1.0)
        .onClick(() => {
          this.goPage(this.currentPage - 1);
        })

      ForEach(this.pageNumbers(), (num: number) => {
        Button(`${num}`)
          .width(40)
          .height(40)
          .fontSize(15)
          .fontColor(num === this.currentPage ? '#FFFFFF' : '#4A4A4A')
          .backgroundColor(num === this.currentPage ? '#156B45' : Color.Transparent)
          .borderRadius(8)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.goPage(num);
          })
      })

      Button('下一页')
        .height(36)
        .fontSize(13)
        .fontColor(this.currentPage >= this.totalPages ? '#C0C0C0' : '#4A4A4A')
        .backgroundColor('#00000000')
        .borderRadius(18)
        .enabled(this.currentPage < this.totalPages && !this.isLoading)
        .opacity(this.currentPage >= this.totalPages ? 0.4 : 1.0)
        .onClick(() => {
          this.goPage(this.currentPage + 1);
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ top: 10, bottom: 10 })
    .backgroundColor('#F5F3EE')
  }

  @Builder
  bottomTabs() {
    Row() {
      this.tabItem('首页', 0)
      this.tabItem('档案', 1)
      this.tabItem('食谱', 2)
      this.tabItem('统计', 3)
      this.tabItem('我的', 4)
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .padding({ bottom: 8 })
  }

  @Builder
  tabItem(label: string, index: number) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor(this.activeTab === index ? '#156B45' : '#9B9B9B')
        .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Normal)
      if (this.activeTab === index) {
        Text('')
          .width(20)
          .height(3)
          .backgroundColor('#156B45')
          .borderRadius(1.5)
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.activeTab = index;
      if (index === 0) {
        router.replaceUrl({ url: 'pages/Index' });
      }
    })
  }
}
