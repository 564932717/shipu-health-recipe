import { HealthProfile, MealPlan, Recipe } from '../common/Models';
import { MockData } from '../common/MockData';
import { ApiClient } from '../services/ApiClient';

@Component
export struct RecommendationPage {
  @State plan: MealPlan = MockData.mealPlan;

  aboutToAppear() {
    this.refresh();
  }

  async refresh() {
    const profile: HealthProfile = await ApiClient.getProfile(ApiClient.currentUserId);
    this.plan = await ApiClient.recommend(profile);
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Row() {
          Text('AI 三餐推荐')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Button('换一换')
            .height(36)
            .backgroundColor('#156B45')
            .onClick(() => this.refresh())
        }
        .width('100%')

        this.recipeBlock('早餐', this.plan.breakfast[0])
        this.recipeBlock('午餐', this.plan.lunch[0])
        this.recipeBlock('晚餐', this.plan.dinner[0])
        this.recipeBlock('加餐', this.plan.snack[0])

        Text(`预估摄入：${this.plan.estimatedIntake.dailyCalories} 千卡，${this.plan.estimatedIntake.macroRatio}`)
          .fontSize(14)
          .fontColor('#4D5A50')
          .padding(12)
          .backgroundColor('#E8F4EC')
          .borderRadius(8)
          .width('100%')
      }
      .padding(16)
    }
    .backgroundColor('#F6F8F5')
  }

  @Builder
  recipeBlock(title: string, recipe: Recipe) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(14)
        .fontColor('#66706A')
      Text(recipe.name)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      Text(`${recipe.calories} 千卡 | 蛋白质 ${recipe.proteinGram}g | 脂肪 ${recipe.fatGram}g | 碳水 ${recipe.carbohydrateGram}g`)
        .fontSize(13)
        .fontColor('#4D5A50')
      Text(`食材：${recipe.ingredients.join('、')}`)
        .fontSize(13)
        .fontColor('#4D5A50')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .width('100%')
  }
}
