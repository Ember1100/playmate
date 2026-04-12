<template>
  <view class="market">
    <!-- 顶部4个Tab -->
    <view class="market__tabs">
      <view
        v-for="tab in tabs"
        :key="tab.key"
        class="market__tab"
        :class="{ active: activeTab === tab.key }"
        @click="activeTab = tab.key"
      >{{ tab.label }}</view>
    </view>

    <!-- 失物招领 -->
    <view v-if="activeTab === 'lost'" class="market__panel">
      <view class="market__section-header">
        <view class="market__toolbar">
          <view class="market__icon-btn" @click="uni.navigateBack()">
            <text class="market__icon-btn-text">←</text>
          </view>
          <view class="market__search">
            <text class="market__search-icon">🔍</text>
            <input class="market__search-input" placeholder="搜索失物/招领" placeholder-style="color:#9e9e9e" />
          </view>
        </view>
        <view class="market__title-row">
          <text class="market__section-title">失物招领</text>
          <view class="market__publish-btn"
            @click="uni.navigateTo({url:'/pages/market/lost-found/publish'})">
            <text class="market__publish-text">+ 发布</text>
          </view>
        </view>
        <!-- 子Tab -->
        <view class="market__subtab-card">
          <view class="market__subtabs">
            <view
              v-for="sub in lostSubtabs"
              :key="sub.key"
              class="market__subtab"
              :class="{ active: activeLostSub === sub.key }"
              @click="activeLostSub = sub.key"
            >
              <text>{{ sub.label }}</text>
              <view v-if="activeLostSub === sub.key" class="market__subtab-line" />
            </view>
          </view>
        </view>
      </view>
      <!-- 列表 -->
      <scroll-view scroll-y class="market__list-scroll">
        <view class="market__list">
          <view
            v-for="item in lostItems"
            :key="item.id"
            class="market__lost-item"
            @click="uni.navigateTo({url:'/pages/market/lost-found/detail?id='+item.id})"
          >
            <image class="market__lost-img" :src="item.image" mode="aspectFill" />
            <view class="market__lost-info">
              <text class="market__lost-title">{{ item.title }}</text>
              <view class="market__lost-tags">
                <text
                  v-for="tag in item.tags"
                  :key="tag"
                  class="market__item-tag"
                >{{ tag }}</text>
              </view>
              <text class="market__lost-code">编号：{{ item.code }}</text>
            </view>
          </view>
        </view>
      </scroll-view>
    </view>

    <!-- 二手闲置 -->
    <view v-if="activeTab === 'second'" class="market__panel">
      <view class="market__section-header">
        <view class="market__toolbar">
          <view class="market__search">
            <text class="market__search-icon">🔍</text>
            <input class="market__search-input" placeholder="搜索二手好物" placeholder-style="color:#9e9e9e" />
          </view>
        </view>
        <view class="market__title-row">
          <text class="market__section-title">二手闲置</text>
          <view class="market__publish-btn"
            @click="uni.navigateTo({url:'/pages/market/second-hand/publish'})">
            <text class="market__publish-text">+ 发布</text>
          </view>
        </view>
        <view class="market__subtab-card">
          <view class="market__subtabs">
            <view
              v-for="sub in secondSubtabs"
              :key="sub.key"
              class="market__subtab"
              :class="{ active: activeSecondSub === sub.key }"
              @click="activeSecondSub = sub.key"
            >
              <text>{{ sub.label }}</text>
              <view v-if="activeSecondSub === sub.key" class="market__subtab-line" />
            </view>
          </view>
        </view>
      </view>
      <scroll-view scroll-y class="market__list-scroll">
        <view class="market__second-grid">
          <view
            v-for="item in secondItems"
            :key="item.id"
            class="market__second-item"
            @click="uni.navigateTo({url:'/pages/market/second-hand/detail?id='+item.id})"
          >
            <image class="market__second-img" :src="item.image" mode="aspectFill" />
            <view class="market__second-info">
              <text class="market__second-title">{{ item.title }}</text>
              <text class="market__second-price">¥{{ item.price }}</text>
              <view class="market__second-meta">
                <text>{{ item.condition }}</text>
                <text>{{ item.location }}</text>
              </view>
            </view>
          </view>
        </view>
      </scroll-view>
    </view>

    <!-- 兼职啦 -->
    <view v-if="activeTab === 'job'" class="market__panel">
      <view class="market__section-header job-header">
        <view class="market__toolbar">
          <view class="market__search">
            <text class="market__search-icon">🔍</text>
            <input class="market__search-input" placeholder="搜索兼职信息" placeholder-style="color:#9e9e9e" />
          </view>
        </view>
        <view class="market__title-row">
          <text class="market__section-title">兼职啦</text>
          <view class="market__publish-btn"
            @click="uni.navigateTo({url:'/pages/market/part-time/publish'})">
            <text class="market__publish-text">+ 发布</text>
          </view>
        </view>
        <view class="market__subtab-card">
          <scroll-view scroll-x class="market__subtabs-scroll">
            <view class="market__subtabs">
              <view
                v-for="sub in jobSubtabs"
                :key="sub.key"
                class="market__subtab"
                :class="{ active: activeJobSub === sub.key }"
                @click="activeJobSub = sub.key"
              >
                <text>{{ sub.label }}</text>
                <view v-if="activeJobSub === sub.key" class="market__subtab-line" />
              </view>
            </view>
          </scroll-view>
        </view>
      </view>
      <scroll-view scroll-y class="market__list-scroll">
        <view class="market__list">
          <view
            v-for="item in jobItems"
            :key="item.id"
            class="market__job-item"
            @click="uni.navigateTo({url:'/pages/market/part-time/detail?id='+item.id})"
          >
            <text class="market__job-title">{{ item.title }}</text>
            <view class="market__job-meta">
              <text
                v-for="tag in item.tags"
                :key="tag"
                class="market__item-tag"
              >{{ tag }}</text>
            </view>
            <text class="market__job-salary">{{ item.salary }}</text>
            <view class="market__job-footer">
              <text>{{ item.location }}</text>
              <text>{{ item.time }}</text>
            </view>
          </view>
        </view>
      </scroll-view>
    </view>

    <!-- 以物换物 -->
    <view v-if="activeTab === 'barter'" class="market__panel">
      <view class="market__section-header">
        <view class="market__toolbar">
          <view class="market__search">
            <text class="market__search-icon">🔍</text>
            <input class="market__search-input" placeholder="搜索换物" placeholder-style="color:#9e9e9e" />
          </view>
        </view>
        <view class="market__title-row">
          <text class="market__section-title">以物换物</text>
          <view class="market__publish-btn"
            @click="uni.navigateTo({url:'/pages/market/barter/publish'})">
            <text class="market__publish-text">+ 发布</text>
          </view>
        </view>
        <view class="market__subtab-card">
          <view class="market__subtabs">
            <view
              v-for="sub in barterSubtabs"
              :key="sub.key"
              class="market__subtab"
              :class="{ active: activeBarterSub === sub.key }"
              @click="activeBarterSub = sub.key"
            >
              <text>{{ sub.label }}</text>
              <view v-if="activeBarterSub === sub.key" class="market__subtab-line" />
            </view>
          </view>
        </view>
      </view>
      <scroll-view scroll-y class="market__list-scroll">
        <view class="market__second-grid">
          <view
            v-for="item in barterItems"
            :key="item.id"
            class="market__barter-item"
            @click="uni.navigateTo({url:'/pages/market/barter/detail?id='+item.id})"
          >
            <image class="market__second-img" :src="item.image" mode="aspectFill" />
            <view class="market__second-info">
              <text class="market__second-title">{{ item.title }}</text>
              <text class="market__barter-want">想换：{{ item.want }}</text>
              <view class="market__second-meta">
                <text>{{ item.location }}</text>
              </view>
            </view>
          </view>
        </view>
      </scroll-view>
    </view>
  </view>
  <PmTabBar :current="1" />
</template>

<script setup lang="ts">
import { ref } from 'vue'
import PmTabBar from '@/components/PmTabBar.vue'

const tabs = [
  { key: 'lost',   label: '失物招领' },
  { key: 'second', label: '二手闲置' },
  { key: 'job',    label: '兼职啦' },
  { key: 'barter', label: '以物换物' },
]
const activeTab = ref('lost')

// 失物招领
const lostSubtabs = [
  { key: 'all', label: '全部' },
  { key: 'lost', label: '失物' },
  { key: 'found', label: '招领' },
]
const activeLostSub = ref('all')
const lostItems = [
  { id: '1', title: '丢失黑色双肩包，内有笔记本电脑', tags: ['电子', '证件'], code: '04-2316-08-42', image: 'https://picsum.photos/seed/bag1/160/160' },
  { id: '2', title: '招领：发现学生证一张', tags: ['证件'], code: '04-2316-09-15', image: 'https://picsum.photos/seed/card1/160/160' },
  { id: '3', title: '丢失蓝色雨伞，图书馆附近', tags: ['生活'], code: '04-2316-10-33', image: 'https://picsum.photos/seed/umbrella1/160/160' },
]

// 二手闲置
const secondSubtabs = [
  { key: 'all', label: '全部' },
  { key: 'digital', label: '数码' },
  { key: 'clothes', label: '服装' },
  { key: 'books', label: '书籍' },
  { key: 'furniture', label: '家具' },
]
const activeSecondSub = ref('all')
const secondItems = [
  { id: '1', title: 'iPhone 13 256G 蓝色', price: '2800', condition: '九成新', location: '上海', image: 'https://picsum.photos/seed/phone1/200/200' },
  { id: '2', title: '考研全套资料2024', price: '88', condition: '八成新', location: '北京', image: 'https://picsum.photos/seed/book2/200/200' },
  { id: '3', title: 'AJ1 Low OG 白蓝 42码', price: '560', condition: '全新', location: '广州', image: 'https://picsum.photos/seed/shoe1/200/200' },
  { id: '4', title: 'MacBook Air M2 8G 256G', price: '6500', condition: '九成新', location: '深圳', image: 'https://picsum.photos/seed/mac1/200/200' },
]

// 兼职
const jobSubtabs = [
  { key: 'all', label: '全部' },
  { key: 'sale', label: '促销' },
  { key: 'teacher', label: '家教' },
  { key: 'delivery', label: '配送' },
  { key: 'office', label: '文职' },
]
const activeJobSub = ref('all')
const jobItems = [
  { id: '1', title: '便利店兼职收银员（周末）', tags: ['零售', '周末'], salary: '150元/天', location: '徐汇区', time: '长期', image: '' },
  { id: '2', title: '初中数学家教（1对1）', tags: ['家教', '在线可'], salary: '200元/小时', location: '浦东新区', time: '寒假', image: '' },
  { id: '3', title: '活动现场工作人员', tags: ['活动', '临时'], salary: '180元/天', location: '静安区', time: '周末2天', image: '' },
]

// 以物换物
const barterSubtabs = [
  { key: 'all', label: '全部' },
  { key: 'digital', label: '数码' },
  { key: 'clothes', label: '服装' },
  { key: 'sports', label: '运动' },
]
const activeBarterSub = ref('all')
const barterItems = [
  { id: '1', title: '九成新索尼耳机', want: '游戏手柄/任意平台', location: '上海', image: 'https://picsum.photos/seed/earphone1/200/200' },
  { id: '2', title: '专业摄影书10本', want: '摄影器材配件', location: '北京', image: 'https://picsum.photos/seed/books3/200/200' },
]
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.market {
  min-height: 100vh;
  background: $color-bg-warm;
  display: flex;
  flex-direction: column;

  &__tabs {
    display: flex;
    align-items: stretch;
    gap: 12rpx;
    padding: 20rpx 20rpx 24rpx;
    background: $color-bg-gray;
    border-bottom: 2rpx solid rgba(0,0,0,0.06);
  }
  &__tab {
    flex: 1;
    padding: 16rpx 8rpx;
    border: none;
    border-radius: 20rpx;
    background: transparent;
    font-size: 22rpx;
    font-weight: 500;
    color: $color-text;
    text-align: center;
    &.active {
      background: #ebebed;
      font-weight: 600;
    }
  }

  &__panel {
    flex: 1;
    display: flex;
    flex-direction: column;
  }

  // 每个子模块的彩色顶部 header
  &__section-header {
    background: $color-primary;
    padding: 20rpx 28rpx 0;
    &.job-header {
      background: linear-gradient(135deg, #FFB703 0%, #FFA000 100%);
    }
  }
  &__toolbar {
    display: flex;
    align-items: center;
    gap: 20rpx;
    margin-bottom: 28rpx;
  }
  &__icon-btn {
    flex-shrink: 0;
    width: 80rpx; height: 80rpx;
    display: flex;
    align-items: center;
    justify-content: center;
    border: none;
    border-radius: 20rpx;
    background: transparent;
    color: #fff;
  }
  &__icon-btn-text {
    font-size: $font-xl;
    color: #fff;
    font-weight: 600;
  }
  &__search {
    flex: 1;
    display: flex;
    align-items: center;
    gap: 16rpx;
    background: #fff;
    border-radius: 999rpx;
    padding: 16rpx 28rpx;
    height: 80rpx;
  }
  &__search-icon { font-size: $font-base; opacity: 0.6; }
  &__search-input {
    flex: 1;
    border: none;
    background: transparent;
    font-size: $font-base;
    color: $color-text-deep;
  }
  &__title-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 24rpx;
    padding: 0 4rpx 28rpx;
  }
  &__section-title {
    font-size: $font-2xl;
    font-weight: 700;
    color: #fff;
    letter-spacing: 1rpx;
  }
  &__publish-btn {
    flex-shrink: 0;
    padding: 16rpx 32rpx;
    border-radius: 999rpx;
    background: rgba(0,0,0,0.15);
    box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.12);
  }
  &__publish-text {
    font-size: $font-base;
    font-weight: 600;
    color: #fff;
    white-space: nowrap;
  }

  // 子Tab card（白色圆角卡）
  &__subtab-card {
    background: #fff;
    border-radius: 32rpx 32rpx 0 0;
    padding: 0 8rpx;
    box-shadow: 0 -8rpx 32rpx rgba(0,0,0,0.08);
  }
  &__subtabs {
    display: flex;
    justify-content: space-between;
    align-items: stretch;
  }
  &__subtabs-scroll { white-space: nowrap; }
  &__subtab {
    flex: 1 0 auto;
    position: relative;
    padding: 28rpx 32rpx 24rpx;
    border: none;
    background: transparent;
    font-size: $font-base;
    font-weight: 500;
    color: #666;
    text-align: center;
    &.active {
      color: $color-text;
      font-weight: 700;
    }
  }
  &__subtab-line {
    position: absolute;
    left: 50%; bottom: 12rpx;
    transform: translateX(-50%);
    width: 56rpx; height: 6rpx;
    border-radius: 4rpx;
    background: $color-primary;
  }

  // 列表滚动区
  &__list-scroll {
    flex: 1;
    background: $color-bg-warm;
  }
  &__list {
    padding: 28rpx;
    display: flex;
    flex-direction: column;
    gap: 24rpx;
  }

  // 失物招领列表项
  &__lost-item {
    display: flex;
    gap: 24rpx;
    padding: 32rpx;
    background: #fff;
    border-radius: 24rpx;
    box-shadow: $shadow-card;
  }
  &__lost-img {
    width: 160rpx; height: 160rpx;
    border-radius: 16rpx;
    flex-shrink: 0;
    background: #eee;
  }
  &__lost-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 12rpx;
  }
  &__lost-title {
    font-size: $font-lg;
    font-weight: 600;
    color: $color-text;
    line-height: 1.3;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  &__lost-tags {
    display: flex;
    gap: 12rpx;
    flex-wrap: wrap;
  }
  &__item-tag {
    font-size: $font-sm;
    color: #666;
    background: #f5f5f5;
    padding: 4rpx 16rpx;
    border-radius: 8rpx;
  }
  &__lost-code { font-size: $font-sm; color: #999; }

  // 二手/换物网格
  &__second-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 24rpx;
    padding: 28rpx;
  }
  &__second-item, &__barter-item {
    background: #fff;
    border-radius: 24rpx;
    overflow: hidden;
    box-shadow: $shadow-card;
  }
  &__second-img {
    width: 100%;
    height: 400rpx;
    display: block;
    background: #eee;
  }
  &__second-info {
    padding: 24rpx 24rpx 20rpx;
    display: flex;
    flex-direction: column;
    gap: 8rpx;
  }
  &__second-title {
    font-size: $font-base;
    font-weight: 600;
    color: $color-text;
    line-height: 1.3;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  &__second-price {
    font-size: $font-xl;
    font-weight: 700;
    color: #ff6b6b;
  }
  &__second-meta {
    display: flex;
    justify-content: space-between;
    font-size: $font-xs;
    color: #999;
  }
  &__barter-want {
    font-size: $font-base;
    color: #ff9800;
    font-weight: 500;
  }

  // 兼职列表项
  &__job-item {
    display: flex;
    flex-direction: column;
    background: #fff;
    border-radius: 24rpx;
    padding: 32rpx;
    box-shadow: $shadow-card;
    gap: 12rpx;
  }
  &__job-title {
    font-size: $font-lg;
    font-weight: 600;
    color: $color-text;
    line-height: 1.3;
  }
  &__job-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 16rpx;
  }
  &__job-salary {
    font-size: $font-xl;
    font-weight: 700;
    color: $color-success;
  }
  &__job-footer {
    display: flex;
    justify-content: space-between;
    font-size: $font-sm;
    color: #999;
  }
}
</style>
