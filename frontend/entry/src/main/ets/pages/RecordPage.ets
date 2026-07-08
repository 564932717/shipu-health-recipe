import { DietRecordRequest, MealType, NutritionSummary } from '../common/Models';
import { MockData } from '../common/MockData';
import { ApiClient } from '../services/ApiClient';

@Component
export struct RecordPage {
  @State foodName: string = '糙米鸡胸蔬菜碗';
  @State calories: string = '560';
  @State summary: NutritionSummary = MockData.summary;

  aboutToAppear() {
    this.loadSummary();
  }

  async loadSummary() {
    this.summary = await ApiClient.getSummary(ApiClient.currentUserId, MockData.mealPlan.assessment.target.dailyCalories);
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('饮食记录')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Column({ space: 10 }) {
          TextInput({ text: this.foodName, placeholder: '食物名称' })
            .height(42)
            .onChange((text: string) => this.foodName = text)
          TextInput({ text: this.calories, placeholder: '热量' })
            .type(InputType.Number)
            .height(42)
            .onChange((text: string) => this.calories = text)
          Button('记录午餐')
            .width('100%')
            .height(42)
            .backgroundColor('#156B45')
            .onClick(async () => {
              const record: DietRecordRequest = {
                userId: ApiClient.currentUserId,
                foodName: this.foodName,
                mealType: MealType.LUNCH,
                calories: Number(this.calories),
                proteinGram: 30,
                fatGram: 12,
                carbohydrateGram: 55
              };
              await ApiClient.addDietRecord(record);
              await this.loadSummary();
            })
        }
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .width('100%')

        Column({ space: 8 }) {
          Text('今日统计')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Text(`热量：${this.summary.totalCalories} 千卡，完成度 ${this.summary.calorieCompletion}%`)
          Text(`蛋白质：${this.summary.totalProteinGram}g`)
          Text(`脂肪：${this.summary.totalFatGram}g`)
          Text(`碳水：${this.summary.totalCarbohydrateGram}g`)
          ForEach(this.summary.suggestions, (item: string) => {
            Text(item)
              .fontSize(13)
              .fontColor('#4D5A50')
          })
        }
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .width('100%')
      }
      .padding(16)
    }
    .backgroundColor('#F6F8F5')
  }
}
