import router from '@ohos.router';

@Component
export struct DashboardPage {
  @Link selectedTabIndex: number;

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Text('首页')
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .width('100%')
          .padding({ left: 18, right: 18, top: 18, bottom: 14 })

        Column() {
          Swiper() {
            this.bannerImage($r('app.media.home_banner_1'))
            this.bannerImage($r('app.media.home_banner_2'))
            this.bannerImage($r('app.media.home_banner_3'))
            this.bannerImage($r('app.media.home_banner_4'))
            this.bannerImage($r('app.media.home_banner_5'))
          }
          .width('100%')
          .height(252)
          .autoPlay(true)
          .interval(3000)
          .duration(650)
          .loop(true)
          .indicator(true)
          .itemSpace(0)
          .borderRadius(20)
          .clip(true)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        Column({ space: 12 }) {
          Row({ space: 12 }) {
            this.featureButton('档', '健康档案', '管理身体数据', 1, '#DDEFE4', '#156B45')
            this.featureButton('谱', '智能食谱', '获取营养方案', 2, '#FFF0C9', '#8B6414')
          }
          .width('100%')

          Row({ space: 12 }) {
            this.featureButton('统', '健康统计', '查看饮食趋势', 3, '#DDEBFA', '#2B6595')
            this.featureButton('我', '我的', '账号与收藏', 4, '#F4E4ED', '#934C70')
          }
          .width('100%')
        }
        .padding({ left: 16, right: 16, top: 18, bottom: 24 })
        .width('100%')

        Column({ space: 14 }) {
          Row() {
            Text('健康食谱小课堂')
              .fontSize(21)
              .fontWeight(FontWeight.Bold)
              .fontColor('#071725')
              .layoutWeight(1)
            Text('科学吃 · 轻松养')
              .fontSize(12)
              .fontColor('#156B45')
          }
          .width('100%')

          this.articleCard('01', '均衡饮食没那么难，四个“4+2”您做到了吗？',
            '每天摄入12种以上、每周25种以上食物并不难。文章用四组“4+2”介绍早餐、午餐、晚餐和天然调味的搭配方法。',
            '均衡饮食', '新华网', 'balanced')
          this.articleCard('02', '科学减脂：建立可以长期坚持的健康计划',
            '从饮食、运动和生活习惯等维度了解科学减脂方法，避免只追求短期体重变化，逐步建立可持续的健康节奏。',
            '科学减脂', 'CalMate', 'weight_loss')
          this.articleCard('03', '食物替代品：怎样获得更优的营养？',
            '通过增加健康脂肪、精益蛋白质和膳食纤维，减少添加糖、加工肉及饱和脂肪，让日常饮食选择更健康。',
            '食品选择', '百汇癌症中心', 'food_choice')
        }
        .padding({ left: 16, right: 16, bottom: 28 })
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F8F3')
  }

  @Builder
  bannerImage(imageResource: Resource) {
    Image(imageResource)
      .width('100%')
      .height('100%')
      .objectFit(ImageFit.Cover)
  }

  @Builder
  featureButton(symbol: string, title: string, subtitle: string, tabIndex: number,
    background: string, accent: string) {
    Row({ space: 12 }) {
      Text(symbol)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(accent)
        .width(42)
        .height(42)
        .textAlign(TextAlign.Center)
        .backgroundColor('#FFFFFFB8')
        .borderRadius(14)

      Column({ space: 3 }) {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .width('100%')
        Text(subtitle)
          .fontSize(11)
          .fontColor('#58675D')
          .maxLines(1)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .height(74)
    .padding({ left: 12, right: 10 })
    .layoutWeight(1)
    .backgroundColor(background)
    .borderRadius(18)
    .onClick(() => {
      this.selectedTabIndex = tabIndex;
    })
  }

  @Builder
  articleCard(number: string, title: string, summary: string, tag: string, source: string, articleId: string) {
    Column({ space: 11 }) {
      Row({ space: 10 }) {
        Text(number)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFF7D6')
          .width(30)
          .height(30)
          .textAlign(TextAlign.Center)
          .backgroundColor('#156B45')
          .borderRadius(15)
        Text(title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .lineHeight(23)
          .layoutWeight(1)
      }
      .width('100%')

      Text(summary)
        .fontSize(13)
        .fontColor('#526158')
        .lineHeight(21)
        .width('100%')

      Row() {
        Text(tag)
          .fontSize(11)
          .fontColor('#156B45')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#E5F2E7')
          .borderRadius(12)
        Blank()
        Text(`来源 · ${source}`)
          .fontSize(11)
          .fontColor('#7A857E')
      }
      .width('100%')

      Row() {
        Blank()
        Text('阅读全文  →')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#156B45')
      }
      .width('100%')
    }
    .padding(15)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#E5ECE2' })
    .borderRadius(18)
    .width('100%')
    .onClick(() => {
      this.openArticle(articleId);
    })
  }

  private openArticle(articleId: string) {
    router.pushUrl({
      url: 'pages/ArticleWebPage',
      params: {
        articleId: articleId
      }
    });
  }
}
