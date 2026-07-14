const widgetStorage = new LocalStorage();

@Entry(widgetStorage)
@Component
struct HealthCardWidget {
  @LocalStorageProp('todayCalories') todayCalories: number = 0;
  @LocalStorageProp('targetCalories') targetCalories: number = 1875;
  @LocalStorageProp('progress') progress: number = 0;
  @LocalStorageProp('recommendation') recommendation: string = 'AI推荐暂未生成';

  private recommendationItems(): string[] {
    const items = this.recommendation.split('\n');
    if (items.length === 1 && this.recommendation.includes('  ')) {
      return this.recommendation.split('  ');
    }
    return items;
  }

  build() {
    Column({ space: 10 }) {
      Row() {
        Text('今日摄入')
          .fontSize(14)
          .fontColor('#CFE3D4')
          .layoutWeight(1)
        Text(`${this.progress}%`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#F8DD77')
      }
      .width('100%')

      Text(`${this.todayCalories} / ${this.targetCalories} 千卡`)
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFF6D5')
        .width('100%')

      Row() {
        Row()
          .width(`${Math.max(0, Math.min(100, this.progress))}%`)
          .height(8)
          .backgroundColor('#83C988')
          .borderRadius(4)
      }
      .width('100%')
      .height(8)
      .backgroundColor('#314554')
      .borderRadius(4)

      Text('今日推荐')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#CFE3D4')
        .width('100%')

      Column() {
        ForEach(this.recommendationItems(), (meal: string) => {
          Row({ space: 10 }) {
            Row()
              .width(4)
              .height(28)
              .backgroundColor('#83C988')
              .borderRadius(2)

            Text(meal)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#F8DD77')
              .lineHeight(20)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .backgroundColor('#102A3D')
          .borderRadius(12)
        }, (meal: string) => meal)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.SpaceEvenly)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .width('100%')
    .height('100%')
    .backgroundColor('#071725')
    .borderRadius(18)
  }
}
