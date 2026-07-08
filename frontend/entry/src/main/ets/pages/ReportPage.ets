import { WeeklyReport } from '../common/Models';
import { MockData } from '../common/MockData';
import { ApiClient } from '../services/ApiClient';

@Component
export struct ReportPage {
  @State report: WeeklyReport = MockData.weeklyReport;

  aboutToAppear() {
    this.load();
  }

  async load() {
    this.report = await ApiClient.getWeeklyReport(ApiClient.currentUserId, MockData.mealPlan.assessment.target.dailyCalories);
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('健康周报')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Column({ space: 8 }) {
          Text(`${this.report.startDate} 至 ${this.report.endDate}`)
            .fontSize(14)
            .fontColor('#66706A')
          Text(this.report.completionLevel)
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#156B45')
          Text(`日均摄入 ${this.report.averageCalories} 千卡，记录 ${this.report.recordDays} 天`)
            .fontSize(14)
        }
        .alignItems(HorizontalAlign.Start)
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .width('100%')

        Column({ space: 8 }) {
          Text('趋势摘要')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          ForEach(this.report.trendHighlights, (item: string) => {
            Text(item).fontSize(14).fontColor('#4D5A50')
          })
        }
        .alignItems(HorizontalAlign.Start)
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .width('100%')

        Column({ space: 8 }) {
          Text('AI 建议')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          ForEach(this.report.aiSuggestions, (item: string) => {
            Text(item).fontSize(14).fontColor('#4D5A50')
          })
        }
        .alignItems(HorizontalAlign.Start)
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
