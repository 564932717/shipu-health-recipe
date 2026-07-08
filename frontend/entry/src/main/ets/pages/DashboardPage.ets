import { HealthProfile, MealPlan } from '../common/Models';
import { MockData } from '../common/MockData';
import { ApiClient } from '../services/ApiClient';

@Component
export struct DashboardPage {
  @State profile: HealthProfile = MockData.profile;
  @State plan: MealPlan = MockData.mealPlan;

  aboutToAppear() {
    this.load();
  }

  async load() {
    this.profile = await ApiClient.getProfile(ApiClient.currentUserId);
    this.plan = await ApiClient.recommend(this.profile);
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('个性化健康食谱规划系统')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1D2B1F')
          .width('100%')

        Row({ space: 12 }) {
          this.metricBlock('BMI', `${this.plan.assessment.bmi}`, this.plan.assessment.bmiLevel)
          this.metricBlock('推荐热量', `${this.plan.assessment.target.dailyCalories}`, '千卡/日')
        }
        .width('100%')

        Column({ space: 8 }) {
          Text('今日推荐')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Text(`早餐：${this.plan.breakfast[0].name}`)
          Text(`午餐：${this.plan.lunch[0].name}`)
          Text(`晚餐：${this.plan.dinner[0].name}`)
          Text(`加餐：${this.plan.snack[0].name}`)
        }
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .width('100%')

        Column({ space: 8 }) {
          Text('AI 建议')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          ForEach(this.plan.assessment.advices, (item: string) => {
            Text(item)
              .fontSize(14)
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
  }

  @Builder
  metricBlock(title: string, value: string, sub: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(13)
        .fontColor('#66706A')
      Text(value)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#156B45')
      Text(sub)
        .fontSize(13)
        .fontColor('#66706A')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .layoutWeight(1)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }
}
