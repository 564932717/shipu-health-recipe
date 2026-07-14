import router from '@ohos.router';

interface ArticleSection {
  heading: string;
  body: string;
}

@Entry
@Component
export struct ArticleWebPage {
  @State articleTitle: string = '';
  @State articleSource: string = '';
  @State articleIntro: string = '';
  @State sections: ArticleSection[] = [];

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    const articleId = params['articleId'] as string;
    this.loadArticle(articleId);
  }

  build() {
    Column({ space: 0 }) {
      Row({ space: 12 }) {
        Text('‹')
          .fontSize(34)
          .fontColor('#071725')
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .backgroundColor('#E8F2E7')
          .borderRadius(20)
          .onClick(() => {
            router.back();
          })

        Column({ space: 2 }) {
          Text('健康食谱小课堂')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#071725')
            .width('100%')
          Text('离线阅读')
            .fontSize(11)
            .fontColor('#156B45')
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .height(64)
      .padding({ left: 14, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 18 }) {
          Column({ space: 10 }) {
            Text(this.articleTitle)
              .fontSize(25)
              .fontWeight(FontWeight.Bold)
              .fontColor('#071725')
              .lineHeight(34)
              .width('100%')
            Text(`内容来源：${this.articleSource} · 已整理为离线科普版`)
              .fontSize(12)
              .fontColor('#718078')
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Text(this.articleIntro)
            .fontSize(15)
            .fontColor('#405146')
            .lineHeight(25)
            .padding(16)
            .backgroundColor('#EAF4E9')
            .borderRadius(16)
            .width('100%')

          ForEach(this.sections, (section: ArticleSection, index: number) => {
            Column({ space: 9 }) {
              Row({ space: 10 }) {
                Text(`${index + 1}`)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFF6D5')
                  .width(26)
                  .height(26)
                  .textAlign(TextAlign.Center)
                  .backgroundColor('#156B45')
                  .borderRadius(13)
                Text(section.heading)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#071725')
                  .layoutWeight(1)
              }
              .width('100%')

              Text(section.body)
                .fontSize(14)
                .fontColor('#526158')
                .lineHeight(24)
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(16)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#E5ECE2' })
            .borderRadius(16)
            .width('100%')
          })

          Text('本文用于日常健康知识学习，具体饮食安排应结合个人身体情况。')
            .fontSize(12)
            .fontColor('#7A857E')
            .lineHeight(19)
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        .padding({ left: 16, right: 16, top: 20, bottom: 32 })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F8F3')
  }

  private loadArticle(articleId: string) {
    if (articleId === 'balanced') {
      this.loadBalancedArticle();
    } else if (articleId === 'weight_loss') {
      this.loadWeightLossArticle();
    } else {
      this.loadFoodChoiceArticle();
    }
  }

  private loadBalancedArticle() {
    this.articleTitle = '均衡饮食没那么难，四个“4+2”您做到了吗？';
    this.articleSource = '新华网、健康中国';
    this.articleIntro = '均衡饮食首先要做到食物多样。谷薯、杂豆、坚果、肉蛋奶、蔬菜、水果和油脂应合理搭配，同时优先选择应季食物和健康烹饪方法。';
    this.sections = [
      { heading: '每天12种、每周25种', body: '《中国居民膳食指南（2022）》建议平均每天摄入12种以上食物、每周25种以上。少量组合多种天然食材，比依靠单一“营养食品”更容易获得全面营养。' },
      { heading: '早餐与上午加餐的“4+2”', body: '早餐可以安排一种全谷物、一份牛奶、一个鸡蛋和一种蔬菜；上午加餐选择一个西红柿和一种水果，让能量与蛋白质供应更加稳定。' },
      { heading: '午餐与下午加餐的“4+2”', body: '午餐可由糙米、瘦肉和两种蔬菜组成；下午加餐选择一根黄瓜和一种水果。主食、蛋白质与蔬菜合理搭配，有助于提高饱腹感。' },
      { heading: '晚餐与晚上加餐的“4+2”', body: '晚餐选择薯类、一种水产品或豆制品以及两种蔬菜；晚上如有需要，可少量选择核桃、杏仁、腰果等两种树坚果。' },
      { heading: '天然调味与油脂多样化', body: '使用葱、姜、蒜、花椒等天然香料增加风味，并合理轮换不同植物油。减少重盐、重糖酱料，让食材本身成为味道的主体。' },
      { heading: '营养补充不宜盲目', body: '天然食物应是营养来源的基础。营养素摄入过少或过多都可能影响健康，如需使用营养补充剂，应根据个人情况并在专业人员指导下进行。' }
    ];
  }

  private loadWeightLossArticle() {
    this.articleTitle = '科学减脂：建立可以长期坚持的健康计划';
    this.articleSource = 'CalMate';
    this.articleIntro = '科学减脂不是短期节食，而是通过合理能量缺口、均衡饮食、规律运动和稳定作息，逐步减少多余脂肪并尽量保留肌肉。';
    this.sections = [
      { heading: '设定现实且可衡量的目标', body: '先记录体重、腰围和日常活动情况，再设定阶段目标。关注数周的变化趋势，不要因一天的体重波动频繁改变计划。' },
      { heading: '建立温和的能量缺口', body: '通过调整食物份量和增加活动量创造适度缺口，避免极端低热量饮食。过度节食容易造成疲劳、饥饿反弹和肌肉流失。' },
      { heading: '每餐保证优质蛋白质', body: '鱼、蛋、奶、瘦肉、豆腐和豆类能够提供蛋白质。减脂期间合理摄入蛋白质，有助于维持饱腹感和身体组织。' },
      { heading: '提高蔬菜与膳食纤维比例', body: '用蔬菜、全谷物和适量水果替代一部分精制主食与高能量零食。纤维丰富的食物通常更耐咀嚼，也更有利于控制食量。' },
      { heading: '结合有氧运动与力量训练', body: '快走、慢跑、骑行等活动可以增加能量消耗；力量训练有助于维持肌肉。应从当前能力出发，逐步增加训练频率和强度。' },
      { heading: '增加日常非运动活动', body: '步行通勤、走楼梯、做家务和减少久坐都会累积消耗。与偶尔一次高强度训练相比，稳定的日常活动更容易长期坚持。' },
      { heading: '保证睡眠并管理压力', body: '睡眠不足和长期压力可能影响食欲与饮食选择。保持相对固定的作息，并为放松、运动和正常用餐预留时间。' },
      { heading: '定期复盘而不是追求完美', body: '每周查看饮食、活动和身体变化，找到最容易执行的调整。偶尔偏离计划并不代表失败，关键是下一餐、下一天重新回到节奏。' }
    ];
  }

  private loadFoodChoiceArticle() {
    this.articleTitle = '食物替代品：怎样获得更优的营养？';
    this.articleSource = '百汇癌症中心';
    this.articleIntro = '健康饮食不一定需要彻底改变菜单。通过替换部分食材、比较食品标签以及调整烹饪方式，就能在保留口味的同时改善整体营养。';
    this.sections = [
      { heading: '优先选择健康脂肪', body: '鲑鱼、鲭鱼等油性鱼类，以及牛油果、坚果、种籽和橄榄油含有较多不饱和脂肪。可用它们适量替代黄油、奶油和动物皮肤中的脂肪。' },
      { heading: '选择精益蛋白质', body: '无皮鸡胸肉、鱼虾、鸡蛋、低脂乳制品、豆腐和豆类都是常见选择。减少加工肉类，并控制红肉的摄入频率和份量。' },
      { heading: '增加膳食纤维', body: '全麦制品、蔬菜、水果和豆类能够增加纤维摄入，有助于消化健康、饱腹感以及血糖和胆固醇管理。' },
      { heading: '减少添加糖和饱和脂肪', body: '少选含糖饮料、甜点及大量添加糖的加工食品。烹调时可用菜籽油、大豆油或橄榄油替代部分黄油、棕榈油和椰子油。' },
      { heading: '学会比较食品标签', body: '比较同类食品时，应在相同重量或份量基础上查看能量、糖、钠、脂肪和纤维。不要只看包装正面的宣传语。' },
      { heading: '采用更健康的烹饪方式', body: '蒸、煮、炖、烤和少油快炒通常比油炸更容易控制脂肪摄入。食谱主体不必改变，只调整烹调方法也能带来改善。' },
      { heading: '用天然香草和香料增味', body: '生姜、姜黄、柠檬、西红柿、辣椒、香菜、胡椒和肉桂都能丰富风味。减少高度加工酱料，可同步降低盐、糖和添加剂摄入。' },
      { heading: '从一个小替换开始', body: '健康生活需要均衡饮食、适量进食和整体生活方式共同支持。从每天能够坚持的一项替换开始，再逐步形成长期习惯。' }
    ];
  }
}
