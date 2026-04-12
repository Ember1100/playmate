<template>
  <view class="fun">
    <!-- Hero -->
    <view class="fun__hero">
      <image class="fun__hero-img" src="/static/quwan-banner.png" mode="aspectFill" />
      <view class="fun__hero-gradient" />
      <view class="fun__ai-tag"><text>✨ AI 推荐</text></view>
      <view class="fun__hero-title-block">
        <view class="fun__sparkles">
          <text>✨</text><text>🎉</text><text>✨</text>
        </view>
        <text class="fun__hero-title">趣 玩</text>
        <view class="fun__hero-sub-wrap">
          <text class="fun__hero-sub">让生活更有趣</text>
        </view>
      </view>
      <view class="fun__hero-footer">
        <text class="fun__hf-left">{{ activities.length }}+ 场活动</text>
        <view class="fun__hf-center"><text>本周精选</text></view>
        <text class="fun__hf-right">免费报名 ›</text>
      </view>
    </view>

    <scroll-view scroll-y class="fun__scroll">
      <!-- 图标快捷入口 -->
      <view class="fun__icon-grid">
        <view
          v-for="ic in iconEntries"
          :key="ic.label"
          class="fun__icon-cell"
          @click="uni.navigateTo({url:'/pages/fun/category?tab='+ic.label})"
        >
          <view class="fun__ic-wrap">
            <text class="fun__ic-emoji">{{ ic.emoji }}</text>
          </view>
          <text class="fun__ic-label">{{ ic.label }}</text>
        </view>
      </view>

      <view class="fun__divider" />

      <!-- 筛选区 -->
      <view class="fun__filter">
        <view class="fun__filter-dots">
          <view class="fun__dot orange" />
          <view class="fun__dot green" />
          <view class="fun__dot orange" />
        </view>
        <scroll-view scroll-x class="fun__pills-scroll">
          <view class="fun__pills">
            <view
              v-for="pill in pills"
              :key="pill"
              class="fun__pill"
              :class="{ active: activePill === pill }"
              @click="activePill = pill"
            >{{ pill }}</view>
          </view>
        </scroll-view>
      </view>

      <!-- 活动 Feed：今日推荐 -->
      <view class="fun__feed-section">
        <view class="fun__feed-section-title">
          <view class="fun__feed-bar" />
          <text>今日推荐</text>
        </view>
        <view class="fun__feed-row">
          <scroll-view scroll-x class="fun__feed-scroll">
            <view v-for="item in activities" :key="item.id" class="fun__feed-card">
              <view class="fun__feed-card-img-wrap">
                <image :src="item.cover" mode="aspectFill" style="width:100%;height:100%" />
              </view>
              <text class="fun__feed-card-title">{{ item.title }}</text>
            </view>
          </scroll-view>
        </view>
      </view>

      <!-- 活动 Feed：户外周末 -->
      <view class="fun__feed-section">
        <view class="fun__feed-section-title">
          <view class="fun__feed-bar" />
          <text>户外周末</text>
        </view>
        <view class="fun__feed-row">
          <scroll-view scroll-x class="fun__feed-scroll">
            <view v-for="item in outdoorActivities" :key="item.id" class="fun__feed-card">
              <view class="fun__feed-card-img-wrap">
                <image :src="item.cover" mode="aspectFill" style="width:100%;height:100%" />
              </view>
              <text class="fun__feed-card-title">{{ item.title }}</text>
            </view>
          </scroll-view>
        </view>
      </view>

      <view class="fun__tip"><text>活动报名功能即将上线 🎉</text></view>
    </scroll-view>
  </view>
  <PmTabBar :current="3" />
</template>

<script setup lang="ts">
import { ref } from 'vue'
import PmTabBar from '@/components/PmTabBar.vue'

const iconEntries = [
  { emoji: '🏃', label: '运动' },
  { emoji: '🎨', label: '文艺' },
  { emoji: '🍜', label: '美食' },
  { emoji: '🏕️', label: '户外' },
  { emoji: '🎵', label: '音乐' },
  { emoji: '📚', label: '学习' },
  { emoji: '🎭', label: '娱乐' },
]

const pills = ['全部', '周末', '免费', '运动', '音乐', '美食', '文化']
const activePill = ref('全部')

const activities = ref([
  { id: '1', title: '城市骑行打卡 · 周六早8点', cover: 'https://picsum.photos/seed/bike2/300/225' },
  { id: '2', title: '周末读书会 · 《原则》共读', cover: 'https://picsum.photos/seed/read2/300/225' },
  { id: '3', title: '街头音乐节 · 本地原创', cover: 'https://picsum.photos/seed/music2/300/225' },
  { id: '4', title: '美食探店团 · 宝藏小店', cover: 'https://picsum.photos/seed/food2/300/225' },
])

const outdoorActivities = ref([
  { id: '5', title: '露营野炊 · 郊野公园', cover: 'https://picsum.photos/seed/camp2/300/225' },
  { id: '6', title: '徒步爬山 · 黄浦江沿岸', cover: 'https://picsum.photos/seed/hike2/300/225' },
  { id: '7', title: '飞盘活动 · 共青森林公园', cover: 'https://picsum.photos/seed/frisbee2/300/225' },
])
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.fun {
  min-height: 100vh;
  background: $color-bg;

  &__hero {
    position: relative;
    width: 100%;
    height: min(52vw, 440rpx);
    overflow: hidden;
  }
  &__hero-img {
    width: 100%;
    height: 100%;
    display: block;
    background: $color-primary-light;
  }
  &__hero-gradient {
    position: absolute;
    inset: 0;
    background: linear-gradient(180deg,
      rgba(255,183,3,0.15) 0%,
      transparent 35%,
      transparent 55%,
      rgba(0,0,0,0.45) 100%);
    pointer-events: none;
  }
  &__ai-tag {
    position: absolute;
    top: 20rpx; left: 20rpx;
    z-index: 2;
    font-size: $font-xs;
    color: $color-text-deep;
    padding: 8rpx 20rpx;
    border-radius: 12rpx;
    background: $color-primary-light;
    backdrop-filter: blur(6px);
  }
  &__hero-title-block {
    position: absolute;
    left: 50%; top: 50%;
    transform: translate(-50%, -52%);
    z-index: 2;
    text-align: center;
    width: 92%;
  }
  &__sparkles {
    display: flex;
    justify-content: center;
    gap: 8rpx;
    margin-bottom: 4rpx;
    font-size: $font-sm;
  }
  &__hero-title {
    font-size: clamp(64rpx, 9vw, 80rpx);
    font-weight: 400;
    color: #fff;
    letter-spacing: 4rpx;
    text-shadow: 0 4rpx 24rpx rgba(255,183,3,0.55), 0 2rpx 0 rgba(0,0,0,0.2);
    display: block;
  }
  &__hero-sub-wrap {
    display: flex;
    justify-content: center;
    margin-top: 16rpx;
  }
  &__hero-sub {
    font-size: $font-base;
    font-weight: 600;
    color: $color-text-deep;
    padding: 12rpx 32rpx;
    border-radius: 999rpx;
    background: $color-primary;
    box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.12);
  }
  &__hero-footer {
    position: absolute;
    left: 0; right: 0; bottom: 0;
    z-index: 2;
    padding: 20rpx 20rpx 24rpx;
    display: grid;
    grid-template-columns: 1fr auto 1fr;
    align-items: end;
    gap: 12rpx;
    background: linear-gradient(0deg, rgba(0,0,0,0.5) 0%, transparent 100%);
  }
  &__hf-left { font-size: $font-xs; color: rgba(255,255,255,0.95); }
  &__hf-center {
    font-size: $font-xs;
    color: $color-text-deep;
    background: $color-primary-light;
    padding: 10rpx 24rpx;
    border-radius: 12rpx;
    white-space: nowrap;
    box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.12);
  }
  &__hf-right { font-size: $font-xs; color: #fff; justify-self: end; }

  &__scroll {
    background: $color-bg;
  }

  // 图标入口
  &__icon-grid {
    display: flex;
    justify-content: space-between;
    padding: 36rpx 24rpx 40rpx;
    background: $color-bg;
    gap: 12rpx;
  }
  &__icon-cell {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    gap: 12rpx;
  }
  &__ic-wrap {
    width: 80rpx; height: 80rpx;
    background: $color-primary-light;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  &__ic-emoji { font-size: $font-xl; }
  &__ic-label { font-size: $font-xs; font-weight: 500; color: $color-text; }

  &__divider {
    height: 2rpx;
    background: $color-border;
    margin: 0 24rpx;
  }

  // 筛选区
  &__filter {
    background: linear-gradient(180deg, #FFF5E0 0%, #FFEDC2 55%, $color-primary-light 100%);
    padding: 28rpx 0 32rpx;
  }
  &__filter-dots {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 16rpx;
    margin-bottom: 28rpx;
  }
  &__dot {
    width: 14rpx; height: 14rpx;
    border-radius: 50%;
    &.orange { background: $color-primary; }
    &.green  { background: $color-primary-light; }
  }
  &__pills-scroll { white-space: nowrap; }
  &__pills {
    display: flex;
    gap: 20rpx;
    padding: 0 24rpx 16rpx;
  }
  &__pill {
    flex-shrink: 0;
    padding: 16rpx 40rpx;
    border-radius: 999rpx;
    font-size: $font-base;
    font-weight: 500;
    border: 2rpx solid $color-primary;
    background: $color-bg-white;
    color: $color-text-mid;
    &.active {
      background: $color-primary;
      color: #fff;
      border-color: $color-primary;
    }
  }

  // Feed 区
  &__feed-section { margin-bottom: 8rpx; }
  &__feed-section-title {
    display: flex;
    align-items: center;
    gap: 16rpx;
    font-size: $font-lg;
    font-weight: 700;
    color: $color-text;
    padding: 28rpx 24rpx 20rpx;
    line-height: 1.2;
  }
  &__feed-bar {
    width: 8rpx; height: 34rpx;
    background: $color-primary;
    border-radius: 4rpx;
    flex-shrink: 0;
  }
  &__feed-row {
    background: $color-bg-white;
    margin: 0 24rpx 24rpx;
    border-radius: 24rpx;
    padding: 24rpx 0 28rpx 24rpx;
    box-shadow: $shadow-soft;
  }
  &__feed-scroll {
    display: flex;
    gap: 24rpx;
    overflow-x: auto;
    padding-right: 24rpx;
    white-space: nowrap;
  }
  &__feed-card {
    flex: 0 0 84%;
    max-width: 336rpx;
    min-width: 296rpx;
    display: inline-block;
  }
  &__feed-card-img-wrap {
    border-radius: 16rpx;
    overflow: hidden;
    aspect-ratio: 4 / 3;
    background: #ececec;
    display: block;
    width: 100%;
  }
  &__feed-card-title {
    display: block;
    margin-top: 16rpx;
    font-size: $font-base;
    font-weight: 500;
    line-height: 1.45;
    color: $color-text;
    white-space: normal;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  &__tip {
    text-align: center;
    padding: 40rpx;
    font-size: $font-sm;
    color: $color-text-hint;
  }
}
</style>
