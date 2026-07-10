import router from '@ohos.router';
import { Recipe } from '../common/Models';
import { ApiClient } from '../services/ApiClient';

@Entry
@Component
export struct RecipeDetailPage {
  @State recipe: Recipe | null = null;
  @State isFavorite: boolean = false;
  @State loading: boolean = true;
  @State message: string = '';
  @StorageLink('favIds') favIds: string[] = [];
  private recipeId: string = '';

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.recipeId = params['recipeId'] as string;
    this.load();
  }

  async load() {
    this.loading = true;
    try {
      this.recipe = await ApiClient.getRecipeDetail(this.recipeId);
      this.isFavorite = this.favIds.indexOf(this.recipeId) >= 0;
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '加载食谱详情失败';
    } finally {
      this.loading = false;
    }
  }

  async toggleFavorite() {
    try {
      if (this.isFavorite) {
        await ApiClient.deleteFavoriteRecipe(ApiClient.currentUserId, this.recipeId);
        this.isFavorite = false;
        this.favIds = this.favIds.filter((id: string) => id !== this.recipeId);
        AppStorage.set('favIds', this.favIds);
      } else {
        await ApiClient.addFavoriteRecipe(ApiClient.currentUserId, this.recipeId);
        this.isFavorite = true;
        const next = this.favIds.slice();
        next.push(this.recipeId);
        this.favIds = next;
        AppStorage.set('favIds', this.favIds);
      }
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '收藏操作失败';
    }
  }

  build() {
    if (this.loading) {
      Column() {
        LoadingProgress()
          .width(48)
          .height(48)
          .color('#156B45')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F4F7F1')
    } else if (this.recipe == null) {
      Column({ space: 16 }) {
        this.backButton()
        Text(this.message.length > 0 ? this.message : '食谱数据未找到')
          .fontSize(16)
          .fontColor('#657064')
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
      .backgroundColor('#F4F7F1')
    } else {
      Scroll() {
        Column({ space: 16 }) {
          this.backButton()
          this.recipeName()
          this.nutritionRow()
          this.categorySection()
          this.ingredientsSection()
          this.stepsSection()
          this.infoCards()
          this.favoriteButton()
        }
        .padding({ left: 16, right: 16, top: 0, bottom: 24 })
      }
      .backgroundColor('#F4F7F1')
    }
  }

  @Builder
  backButton() {
    Row() {
      Button('< 返回')
        .height(38)
        .fontSize(15)
        .fontColor('#405146')
        .backgroundColor('#EEF4EA')
        .borderRadius(19)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          router.back();
        })
    }
    .width('100%')
    .padding({ top: 12 })
  }

  @Builder
  recipeName() {
    Text(this.recipe!.name)
      .fontSize(24)
      .fontWeight(FontWeight.Bold)
      .fontColor('#071725')
      .width('100%')
      .padding({ top: 4 })
  }

  @Builder
  nutritionRow() {
    Row({ space: 10 }) {
      this.nutritionCard('热量', this.recipe!.calories, '千卡', '#F8DD77')
      this.nutritionCard('蛋白质', this.recipe!.proteinGram, 'g', '#A8D9A1')
      this.nutritionCard('脂肪', this.recipe!.fatGram, 'g', '#E7B4C8')
      this.nutritionCard('碳水', this.recipe!.carbohydrateGram, 'g', '#93BFE8')
    }
    .width('100%')
  }

  @Builder
  nutritionCard(label: string, value: number, unit: string, color: string) {
    Column({ space: 4 }) {
      Text(`${value}${unit}`)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
      Text(label)
        .fontSize(12)
        .fontColor('#657064')
    }
    .width('22%')
    .padding({ top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .border({ width: { top: 3 }, color: color })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  categorySection() {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Text(this.recipe!.category)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#156B45')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#E8F4EC')
          .borderRadius(14)

        ForEach(this.recipe!.tags, (tag: string) => {
          Text(tag)
            .fontSize(12)
            .fontColor('#8B5E22')
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor('#FFF6D5')
            .borderRadius(12)
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  ingredientsSection() {
    Column({ space: 10 }) {
      Text('食材清单')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Column({ space: 8 }) {
        ForEach(this.recipe!.ingredients, (item: string, index: number) => {
          Row({ space: 10 }) {
            Text(`${index + 1}`)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#156B45')
              .width(24)
              .height(24)
              .textAlign(TextAlign.Center)
              .backgroundColor('#E8F4EC')
              .borderRadius(12)

            Text(item)
              .fontSize(15)
              .fontColor('#071725')
              .layoutWeight(1)
          }
          .width('100%')
        })
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  stepsSection() {
    Column({ space: 10 }) {
      Text('制作步骤')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
        .width('100%')

      Column({ space: 12 }) {
        ForEach(this.recipe!.steps, (step: string, index: number) => {
          Row({ space: 10 }) {
            Text(`${index + 1}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFF6D5')
              .width(30)
              .height(30)
              .textAlign(TextAlign.Center)
              .backgroundColor('#156B45')
              .borderRadius(15)

            Text(step)
              .fontSize(14)
              .fontColor('#405146')
              .lineHeight(22)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        })
      }
      .width('100%')
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
  }

  @Builder
  infoCards() {
    Row({ space: 10 }) {
      this.infoCard('适合人群', this.recipe!.category, '#F8DD77')
      this.infoCard('制作时间', this.recipe!.cookTime, '#A8D9A1')
      this.infoCard('难度', this.recipe!.difficulty, '#93BFE8')
    }
    .width('100%')
  }

  @Builder
  infoCard(label: string, value: string, color: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#071725')
      Text(label)
        .fontSize(12)
        .fontColor('#657064')
    }
    .layoutWeight(1)
    .padding({ top: 14, bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .border({ width: { left: 4 }, color: color })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  favoriteButton() {
    Button(this.isFavorite ? '已收藏' : '收藏')
      .height(50)
      .width('100%')
      .fontSize(17)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.isFavorite ? '#156B45' : '#FFF6D5')
      .backgroundColor(this.isFavorite ? '#E8F4EC' : '#156B45')
      .borderRadius(25)
      .onClick(async () => {
        await this.toggleFavorite();
      })
  }
}
