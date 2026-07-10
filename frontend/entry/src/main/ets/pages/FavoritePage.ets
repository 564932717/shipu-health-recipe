import router from '@ohos.router';
import { Recipe } from '../common/Models';
import { ApiClient } from '../services/ApiClient';

@Entry
@Component
export struct FavoritePage {
  @State recipes: Recipe[] = [];
  @State message: string = '';

  aboutToAppear() {
    this.load();
  }

  async load() {
    try {
      this.recipes = await ApiClient.listFavoriteRecipes(ApiClient.currentUserId);
      this.message = '';
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '收藏列表加载失败，请稍后重试';
    }
  }

  async removeFavorite(recipeId: string) {
    try {
      await ApiClient.deleteFavoriteRecipe(ApiClient.currentUserId, recipeId);
      const favs = AppStorage.get<string[]>('favIds') ?? [];
      AppStorage.setOrCreate('favIds', favs.filter((id: string) => id !== recipeId));
      await this.load();
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '取消收藏失败，请稍后重试';
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        this.headerSection()
        this.countSection()
        this.listSection()
      }
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
    }
    .backgroundColor('#F4F7F1')
  }

  @Builder
  headerSection() {
    Column({ space: 10 }) {
      Row() {
        Text('< 返回')
          .fontSize(15)
          .fontColor('#156B45')
          .fontWeight(FontWeight.Bold)
          .padding({ left: 4, right: 14, top: 8, bottom: 8 })
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')

      Text('我的收藏')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')
    }
    .width('100%')
  }

  @Builder
  countSection() {
    Column() {
      Text(`共收藏 ${this.recipes.length} 道食谱`)
        .fontSize(15)
        .fontColor('#657064')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .width('100%')
    }
    .width('100%')
  }

  @Builder
  listSection() {
    Column({ space: 10 }) {
      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(13)
          .fontColor('#8B5E22')
          .padding(12)
          .backgroundColor('#FFF4D5')
          .borderRadius(10)
          .width('100%')
      }

      if (this.recipes.length === 0 && this.message.length === 0) {
        Column({ space: 8 }) {
          Text('暂无收藏食谱')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#071725')
          Text('去食谱中心浏览并收藏喜欢的食谱吧')
            .fontSize(13)
            .fontColor('#657064')
        }
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(18)
        .width('100%')
      }

      ForEach(this.recipes, (recipe: Recipe) => {
        this.recipeCard(recipe)
      })
    }
    .width('100%')
  }

  @Builder
  recipeCard(recipe: Recipe) {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text(recipe.name)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .width('100%')

        Text(`分类：${recipe.category}`)
          .fontSize(13)
          .fontColor('#657064')
          .width('100%')

        Row({ space: 16 }) {
          Row({ space: 4 }) {
            Text('热量')
              .fontSize(12)
              .fontColor('#657064')
            Text(`${recipe.calories}千卡`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#071725')
          }

          Row({ space: 4 }) {
            Text('蛋白质')
              .fontSize(12)
              .fontColor('#657064')
            Text(`${recipe.proteinGram}g`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#071725')
          }

          Row({ space: 4 }) {
            Text('脂肪')
              .fontSize(12)
              .fontColor('#657064')
            Text(`${recipe.fatGram}g`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#071725')
          }

          Row({ space: 4 }) {
            Text('碳水')
              .fontSize(12)
              .fontColor('#657064')
            Text(`${recipe.carbohydrateGram}g`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#071725')
          }
        }
        .width('100%')

        Text(`标签：${recipe.tags.join(' / ')}`)
          .fontSize(12)
          .fontColor('#405146')
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)

      Button('取消收藏')
        .height(34)
        .fontSize(13)
        .fontColor('#071725')
        .backgroundColor('#F4E8BA')
        .borderRadius(17)
        .width('100%')
        .onClick(async () => {
          await this.removeFavorite(recipe.id);
        })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
    .onClick(() => {
      router.pushUrl({ url: 'pages/RecipeDetailPage', params: { recipeId: recipe.id } });
    })
  }
}
