<template>
  <view class="category">
    <!-- 顶部 hero 图 -->
    <image class="category__banner" :src="bannerUrl" mode="aspectFill" />

    <!-- 顶部标题导航 -->
    <view class="category__header">
      <view class="category__back" @click="uni.navigateBack()">
        <text class="category__back-icon">←</text>
      </view>
      <view class="category__tabs">
        <view
          v-for="tab in tabs"
          :key="tab"
          class="category__tab"
          :class="{ active: activeTab === tab }"
          @click="activeTab = tab"
        >
          <text>{{ tab }}</text>
        </view>
      </view>
      <view class="category__msg-btn">
        <text class="category__msg-icon">💬</text>
      </view>
    </view>

    <scroll-view scroll-y class="category__scroll">
      <!-- 日历选择 -->
      <view class="category__calendar-card">
        <text class="category__section-title">活动分类</text>
        <view class="category__calendar-header">
          <text>2026.04</text>
          <text>选择日期</text>
        </view>
        <view class="category__calendar-days">
          <view
            v-for="day in calendarDays"
            :key="day.date"
            class="category__cal-day"
            @click="selectedDate = day.date"
          >
            <text class="category__cal-label">{{ day.label }}</text>
            <view
              class="category__cal-num"
              :class="{ active: selectedDate === day.date }"
            >
              <text>{{ day.date }}</text>
            </view>
            <text class="category__cal-count">{{ day.count }}</text>
          </view>
        </view>
      </view>

      <!-- 近期活动 -->
      <view class="category__activities">
        <text class="category__section-title category__section-title--pad">近期活动瀑布流</text>
        <view class="category__grid">
          <view
            v-for="act in activities"
            :key="act.id"
            class="category__act-card"
          >
            <image class="category__act-img" :src="act.cover" mode="aspectFill" />
            <text class="category__act-title">{{ act.title }}</text>
          </view>
        </view>
      </view>

      <!-- 好物拼团纪念卡 -->
      <view class="category__keepsake">
        <text class="category__section-title category__section-title--pad">好物拼团活动纪念卡</text>
        <view class="category__keepsake-card">
          <view class="category__keepsake-banner">
            <text class="category__keepsake-title">好物拼团·旅行纪念</text>
          </view>
          <view class="category__keepsake-footer">
            <text>好物拼团·旅行纪念</text>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const bannerUrl = 'https://picsum.photos/seed/activity/800/600'

const tabs = ['亲子游', '周边游', '短途旅行']
const activeTab = ref('亲子游')

const calendarDays = [
  { label: '日一', date: '01', count: '0' },
  { label: '一二', date: '05', count: '7' },
  { label: '三三', date: '12', count: '3' },
  { label: '日四', date: '14', count: '5' },
  { label: '日五', date: '15', count: '6' },
  { label: '十八', date: '19', count: '7' },
  { label: '廿五', date: '22', count: '1' },
  { label: '日五', date: '23', count: '8' },
  { label: '六日', date: '27', count: '9' },
]
const selectedDate = ref('22')

const activities = [
  { id: '1', title: '秋日亲子露营',   cover: 'https://picsum.photos/seed/camp3/400/400' },
  { id: '2', title: '周末周边采摘',   cover: 'https://picsum.photos/seed/pick/400/400' },
  { id: '3', title: '户外亲子乐园',   cover: 'https://picsum.photos/seed/park/400/400' },
  { id: '4', title: '田园采摘体验',   cover: 'https://picsum.photos/seed/farm/400/400' },
  { id: '5', title: '森林亲子徒步',   cover: 'https://picsum.photos/seed/forest3/400/400' },
  { id: '6', title: '阳光草地野餐',   cover: 'https://picsum.photos/seed/picnic/400/400' },
]
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.category {
  min-height: 100vh;
  background: linear-gradient(180deg, #FFF9E8 0%, #E8F5E9 100%);
  display: flex;
  flex-direction: column;

  &__banner {
    width: 100%;
    height: 440rpx;
    display: block;
    background: $color-primary-light;
  }

  &__header {
    background: $color-primary;
    padding: 24rpx 32rpx;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16rpx;
    position: sticky;
    top: 0;
    z-index: 10;
  }
  &__back {
    flex-shrink: 0;
  }
  &__back-icon {
    font-size: $font-2xl;
    color: #fff;
    font-weight: 500;
  }
  &__tabs {
    display: flex;
    background: #fff;
    border-radius: 48rpx;
    padding: 8rpx;
    gap: 8rpx;
    flex: 1;
  }
  &__tab {
    flex: 1;
    padding: 16rpx 0;
    border-radius: 40rpx;
    text-align: center;
    font-size: $font-base;
    font-weight: 500;
    color: $color-text-gray;
    &.active {
      background: $color-primary;
      color: #fff;
      font-weight: 600;
    }
  }
  &__msg-btn {
    flex-shrink: 0;
  }
  &__msg-icon {
    font-size: $font-2xl;
    color: #fff;
  }

  &__scroll {
    flex: 1;
  }

  &__section-title {
    display: block;
    font-size: $font-xl;
    font-weight: 600;
    color: $color-text;
    margin-bottom: 32rpx;
    &--pad { padding: 0 32rpx; }
  }

  // 日历卡片
  &__calendar-card {
    background: #fff;
    margin: 32rpx;
    border-radius: 32rpx;
    padding: 32rpx;
    box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.05);
  }
  &__calendar-header {
    display: flex;
    justify-content: space-between;
    margin-bottom: 32rpx;
    font-size: $font-xl;
    font-weight: 600;
    color: $color-text;
  }
  &__calendar-days {
    display: grid;
    grid-template-columns: repeat(9, 1fr);
    gap: 16rpx;
    text-align: center;
  }
  &__cal-day {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4rpx;
  }
  &__cal-label {
    font-size: $font-xs;
    color: $color-text-gray;
  }
  &__cal-num {
    width: 56rpx;
    height: 56rpx;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: $font-base;
    color: $color-text;
    &.active {
      background: $color-primary;
      color: #fff;
    }
  }
  &__cal-count {
    font-size: $font-xs;
    color: $color-text-gray;
  }

  // 活动网格
  &__activities {
    padding-bottom: 32rpx;
  }
  &__grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 24rpx;
    padding: 0 32rpx;
    margin-bottom: 64rpx;
  }
  &__act-card {
    background: #fff;
    border-radius: 32rpx;
    overflow: hidden;
    box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.05);
  }
  &__act-img {
    width: 100%;
    aspect-ratio: 1;
    display: block;
    background: #ececec;
  }
  &__act-title {
    display: block;
    padding: 16rpx;
    text-align: center;
    font-size: $font-sm;
    font-weight: 500;
    color: $color-text;
    line-height: 1.3;
  }

  // 纪念卡
  &__keepsake {
    padding-bottom: 64rpx;
  }
  &__keepsake-card {
    margin: 0 32rpx;
    background: #fff;
    border-radius: 32rpx;
    overflow: hidden;
    box-shadow: 0 4rpx 16rpx rgba(0, 0, 0, 0.05);
  }
  &__keepsake-banner {
    width: 100%;
    height: 360rpx;
    background: url('https://picsum.photos/seed/travel/800/400') center / cover no-repeat;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: $color-primary-light;
  }
  &__keepsake-title {
    font-size: $font-2xl;
    font-weight: 700;
    color: #fff;
    text-shadow: 0 4rpx 8rpx rgba(0, 0, 0, 0.3);
  }
  &__keepsake-footer {
    padding: 32rpx;
    text-align: center;
    color: $color-primary;
    font-weight: 500;
    font-size: $font-base;
    position: relative;
    &::before, &::after {
      content: '';
      position: absolute;
      top: 50%;
      width: 25%;
      height: 2rpx;
      background: $color-primary;
    }
    &::before { left: 32rpx; }
    &::after  { right: 32rpx; }
  }
}
</style>
