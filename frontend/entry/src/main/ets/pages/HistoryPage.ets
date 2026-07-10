import router from '@ohos.router';
import { ApiClient } from '../services/ApiClient';
import { RecipeHistoryItem } from '../common/Models';

@Entry
@Component
export struct HistoryPage {
  @State items: RecipeHistoryItem[] = [];
  @State isLoading: boolean = false;
  @State message: string = '';

  aboutToAppear() {
    this.loadHistory();
  }

  async loadHistory() {
    this.isLoading = true;
    try {
      this.items = await ApiClient.listRecipeHistory(ApiClient.currentUserId);
      this.message = '';
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '浏览历史加载失败，请稍后重试';
    } finally {
      this.isLoading = false;
    }
  }

  async clearAll() {
    try {
      await ApiClient.clearRecipeHistory(ApiClient.currentUserId);
      this.items = [];
      this.message = '';
    } catch (error) {
      this.message = ApiClient.lastError.length > 0 ? ApiClient.lastError : '清除历史失败';
    }
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(16)
          .fontColor('#156B45')
          .padding({ left: 4, right: 12, top: 12, bottom: 12 })
          .onClick(() => {
            router.back();
          })
        Blank()
      }
      .width('100%')
      .padding({ left: 12, right: 16, top: 8, bottom: 4 })

      Scroll() {
        Column({ space: 16 }) {
          Text('浏览历史')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#071725')
            .width('100%')

          Row() {
            Text(`共浏览 ${this.items.length} 道食谱`)
              .fontSize(14)
              .fontColor('#657064')
              .layoutWeight(1)
            if (this.items.length > 0) {
              Button('清除全部')
                .height(30)
                .fontSize(12)
                .fontColor('#8B5E22')
                .backgroundColor('#FFF4D5')
                .borderRadius(15)
                .padding({ left: 12, right: 12 })
                .onClick(async () => {
                  await this.clearAll();
                })
            }
          }
          .width('100%')

          if (this.message.length > 0) {
            Text(this.message)
              .fontSize(13)
              .fontColor('#8B5E22')
              .padding(12)
              .backgroundColor('#FFF4D5')
              .borderRadius(10)
              .width('100%')
          }

          if (this.isLoading) {
            Text('加载中...')
              .fontSize(14)
              .fontColor('#657064')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(24)
          } else if (this.items.length === 0) {
            Text('暂无浏览记录')
              .fontSize(15)
              .fontColor('#657064')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(24)
          } else {
            ForEach(this.items, (item: RecipeHistoryItem) => {
              this.historyCard(item)
            })
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 24 })
      }
      .layoutWeight(1)
    }
    .backgroundColor('#F4F7F1')
    .width('100%')
    .height('100%')
  }

  @Builder
  historyCard(item: RecipeHistoryItem) {
    Column({ space: 10 }) {
      Row() {
        Text(item.recipe.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#071725')
          .layoutWeight(1)
        Text(this.formatTime(item.lastViewedAt))
          .fontSize(12)
          .fontColor('#657064')
      }
      .width('100%')

      Row({ space: 10 }) {
        Text(item.recipe.category)
          .fontSize(13)
          .fontColor('#405146')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#EAF3E4')
          .borderRadius(10)
        Text(`${item.recipe.calories} 千卡`)
          .fontSize(13)
          .fontColor('#405146')
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor('#FFF6D5')
          .borderRadius(10)
      }

      if (item.recipe.tags.length > 0) {
        Row({ space: 6 }) {
          ForEach(item.recipe.tags, (tag: string) => {
            Text(tag)
              .fontSize(11)
              .fontColor('#657064')
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor('#F8FAF5')
              .borderRadius(8)
          })
        }
      }
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .width('100%')
    .onClick(() => {
      router.pushUrl({ url: 'pages/RecipeDetailPage', params: { recipeId: item.recipe.id } });
    })
  }

  private formatTime(iso: string): string {
    if (iso == null || iso.length === 0) {
      return '';
    }
    const date = new Date(iso.replace(' ', 'T'));
    if (Number.isNaN(date.getTime())) {
      return iso.substring(0, 16);
    }
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMin = Math.floor(diffMs / 60000);
    if (diffMin < 1) {
      return '刚刚';
    }
    if (diffMin < 60) {
      return `${diffMin}分钟前`;
    }
    const diffHour = Math.floor(diffMin / 60);
    if (diffHour < 24) {
      return `${diffHour}小时前`;
    }
    const diffDay = Math.floor(diffHour / 24);
    if (diffDay < 7) {
      return `${diffDay}天前`;
    }
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }
}
