<template>
  <view class="buddy">
    <!-- Header -->
    <view class="buddy__header">
      <text class="buddy__header-title">俱乐部兴趣活动</text>
    </view>

    <scroll-view scroll-y class="buddy__scroll">
      <!-- Banner -->
      <view class="buddy__banner-wrap">
        <view class="buddy__banner">
          <!-- 云朵 -->
          <view class="buddy__cloud c1" />
          <view class="buddy__cloud c2" />
          <view class="buddy__cloud c3" />
          <!-- 左侧文字 -->
          <view class="buddy__banner-text">
            <text class="buddy__banner-line">周末不宅</text>
            <text class="buddy__banner-line">组队去野</text>
          </view>
          <!-- 吉祥物 -->
          <text class="buddy__owl">🦉</text>
          <!-- 底部 -->
          <text class="buddy__banner-indicator">1/1</text>
          <view class="buddy__banner-handle" />
        </view>
      </view>

      <!-- Search -->
      <view class="buddy__search-wrap" @click="uni.navigateTo({url:'/pages/buddy/search'})">
        <view class="buddy__search">
          <text class="buddy__search-icon">🔍</text>
          <text class="buddy__search-hint">请输入关键词</text>
        </view>
      </view>

      <!-- 三分类卡片 -->
      <view class="buddy__cat-section">
        <view class="buddy__cat-grid">
          <!-- 线上搭子 -->
          <view class="buddy__cat-card online" @click="uni.navigateTo({url:'/pages/buddy/candidates?type=1'})">
            <view class="buddy__cat-content">
              <text class="buddy__cat-title">线上搭子</text>
              <text class="buddy__cat-desc">快速匹配</text>
            </view>
            <text class="buddy__cat-deco">💻</text>
          </view>
          <!-- 职业搭子（右侧高卡片跨2行） -->
          <view class="buddy__cat-card pro" @click="uni.navigateTo({url:'/pages/buddy/career'})">
            <view class="buddy__cat-content">
              <text class="buddy__cat-title">职业搭子</text>
              <text class="buddy__cat-desc">您的专业老师</text>
            </view>
            <text class="buddy__cat-deco">💼</text>
          </view>
          <!-- 线下搭子 -->
          <view class="buddy__cat-card offline" @click="uni.navigateTo({url:'/pages/buddy/candidates?type=2'})">
            <view class="buddy__cat-content">
              <text class="buddy__cat-title">线下搭子</text>
              <text class="buddy__cat-desc">按照需求进行匹配</text>
            </view>
            <text class="buddy__cat-deco">🤝</text>
          </view>
        </view>
      </view>

      <!-- 标签横滚 -->
      <scroll-view class="buddy__tags" scroll-x :show-scrollbar="false">
        <view class="buddy__tags-inner">
          <view class="buddy__tag" v-for="tag in tags" :key="tag.label"
            @click="uni.navigateTo({url:'/pages/buddy/candidates?tag='+tag.label})">
            <text v-if="tag.emoji" class="buddy__tag-emoji">{{ tag.emoji }}</text>
            <text>{{ tag.label }}</text>
          </view>
        </view>
      </scroll-view>

      <!-- Feed 卡片网格 -->
      <view class="buddy__feed">
        <view
          v-for="item in feedItems"
          :key="item.id"
          class="buddy__feed-card"
          @click="uni.navigateTo({url:'/pages/buddy/detail?id='+item.id})"
        >
          <image class="buddy__feed-img" :src="item.cover" mode="aspectFill" />
          <view class="buddy__feed-info">
            <text class="buddy__feed-title">{{ item.title }}</text>
            <text class="buddy__feed-price">{{ item.price }}</text>
            <text class="buddy__feed-status">{{ item.status }}</text>
          </view>
        </view>
      </view>
    </scroll-view>

    <!-- FAB -->
    <view class="buddy__fab-stack">
      <view class="buddy__fab" @click="uni.navigateTo({url:'/pages/buddy/invitations'})">
        <text class="buddy__fab-icon">📋</text>
      </view>
      <view class="buddy__fab" @click="uni.navigateTo({url:'/pages/im/chat'})">
        <text class="buddy__fab-icon">💬</text>
      </view>
    </view>
  </view>
  <PmTabBar :current="2" />
</template>

<script setup lang="ts">
import PmTabBar from '@/components/PmTabBar.vue'

const tags = [
  { label: '旅行户外' },
  { label: '娱乐搭子', emoji: '🎤' },
  { label: '游戏搭子', emoji: '🎮' },
  { label: '脱单搭子', emoji: '💗' },
  { label: '学习搭子', emoji: '📚' },
  { label: '运动搭子', emoji: '🏃' },
]

const feedItems = [
  { id: '1', title: '星际海渊', price: '价格面议', status: '已预约：0 剩余：10', cover: 'https://picsum.photos/seed/meal/300/240' },
  { id: '2', title: '室内烤肉自助活动', price: '¥58.00', status: '已预约：0 剩余：8', cover: 'https://picsum.photos/seed/bbq/300/240' },
  { id: '3', title: '骑在黎明破晓前露营折叠车', price: '免费', status: '已预约：0 剩余：5', cover: 'https://picsum.photos/seed/friend/300/240' },
  { id: '4', title: '室内网球活动', price: '¥88.00', status: '已预约：0 剩余：12', cover: 'https://picsum.photos/seed/tennis/300/240' },
]
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.buddy {
  min-height: 100vh;
  background-color: $color-bg;
  position: relative;

  // ── Header ──────────────────────────────────────────────
  &__header {
    display: flex;
    align-items: center;
    justify-content: center;
    height: 88rpx;
    background: #fff;
    border-bottom: 2rpx solid #f0f0f0;
  }
  &__header-title {
    font-size: $font-lg;
    font-weight: 700;
    color: #222;
  }

  &__scroll {
    height: calc(100vh - 88rpx - 98px);
  }

  // ── Banner ──────────────────────────────────────────────
  &__banner-wrap {
    padding: 20rpx 24rpx 0;
  }
  &__banner {
    position: relative;
    height: 296rpx;
    border-radius: 36rpx;
    overflow: hidden;
    background: linear-gradient(165deg, #FFE8C0 0%, #FFD166 45%, #FFB703 100%);
  }
  &__cloud {
    position: absolute;
    background: rgba(255,255,255,0.85);
    border-radius: 50%;
    &.c1 { width: 144rpx; height: 72rpx; top: 24rpx; left: 8%; }
    &.c2 { width: 112rpx; height: 56rpx; top: 48rpx; left: 28%; opacity: 0.9; }
    &.c3 { width: 128rpx; height: 64rpx; top: 16rpx; right: 22%; }
  }
  &__banner-text {
    position: absolute;
    left: 32rpx;
    top: 50%;
    transform: translateY(-50%);
    z-index: 2;
    display: flex;
    flex-direction: column;
  }
  &__banner-line {
    font-size: $font-2xl;
    font-weight: 900;
    color: #333;
    letter-spacing: 2rpx;
    line-height: 1.25;
    text-shadow: 0 2rpx 0 rgba(255,255,255,0.6);
  }

  // 猫头鹰吉祥物
  &__owl {
    position: absolute;
    right: 20rpx;
    bottom: 16rpx;
    font-size: 120rpx;
    z-index: 1;
    line-height: 1;
  }

  &__banner-indicator {
    position: absolute;
    right: 20rpx;
    bottom: 16rpx;
    font-size: $font-xs;
    color: rgba(0,0,0,0.45);
    z-index: 3;
  }
  &__banner-handle {
    position: absolute;
    left: 50%;
    bottom: 8rpx;
    transform: translateX(-50%);
    width: 72rpx;
    height: 8rpx;
    background: rgba(0,0,0,0.12);
    border-radius: 4rpx;
    z-index: 3;
  }

  // ── Search ──────────────────────────────────────────────
  &__search-wrap {
    padding: 24rpx 28rpx 20rpx;
  }
  &__search {
    display: flex;
    align-items: center;
    gap: 16rpx;
    background: #FFE8C0;
    border-radius: 999rpx;
    padding: 20rpx 32rpx;
  }
  &__search-icon {
    font-size: $font-lg;
    opacity: 0.6;
  }
  &__search-hint {
    font-size: $font-base;
    color: #9e9e9e;
  }

  // ── Category Grid ────────────────────────────────────────
  &__cat-section {
    padding: 12rpx 24rpx 24rpx;
  }
  &__cat-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    grid-template-rows: 192rpx 192rpx;
    gap: 20rpx;
  }

  // 卡片基础
  &__cat-card {
    border-radius: 36rpx;
    position: relative;
    overflow: hidden;
    box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.06);
    display: flex;
    flex-direction: column;

    &.online  { grid-column: 1; grid-row: 1; background: #FFE8C0; }
    &.offline { grid-column: 1; grid-row: 2; background: #FFE082; }
    &.pro     { grid-column: 2; grid-row: 1 / span 2; background: #FFE8C0; }
  }

  // 卡片文字内容（左上角）
  &__cat-content {
    position: absolute;
    left: 28rpx;
    top: 28rpx;
    z-index: 2;
    display: flex;
    flex-direction: column;
    gap: 8rpx;
  }
  &__cat-title {
    font-size: $font-lg;
    font-weight: 700;
    color: #222;
  }
  &__cat-desc {
    font-size: $font-xs;
    color: #666;
    line-height: 1.4;
  }

  // 卡片右下角大 emoji 装饰
  &__cat-deco {
    position: absolute;
    right: 16rpx;
    bottom: 16rpx;
    font-size: 96rpx;
    line-height: 1;
    opacity: 0.85;
    z-index: 1;
  }

  // ── Tags ────────────────────────────────────────────────
  &__tags {
    white-space: nowrap;
    padding: 0 0 28rpx;
  }
  &__tags-inner {
    display: flex;
    gap: 16rpx;
    padding: 0 24rpx;
  }
  &__tag {
    flex-shrink: 0;
    display: inline-flex;
    align-items: center;
    gap: 8rpx;
    padding: 16rpx 28rpx;
    background: #fff;
    border-radius: 999rpx;
    font-size: $font-base;
    color: $color-text;
    border: 2rpx solid $color-border;
    box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.05);
  }
  &__tag-emoji { font-size: $font-md; }

  // ── Feed ─────────────────────────────────────────────────
  &__feed {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20rpx;
    padding: 0 24rpx 48rpx;
  }
  &__feed-card {
    border-radius: 32rpx;
    overflow: hidden;
    background: #fff;
    box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.06);
  }
  &__feed-img {
    width: 100%;
    aspect-ratio: 1 / 0.8;
    display: block;
    background: #f5f5f5;
  }
  &__feed-info {
    padding: 20rpx;
    display: flex;
    flex-direction: column;
    gap: 6rpx;
  }
  &__feed-title {
    font-size: $font-base;
    font-weight: 700;
    color: $color-text;
    line-height: 1.3;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  &__feed-price {
    font-size: $font-base;
    color: #ff6700;
    font-weight: 500;
  }
  &__feed-status {
    font-size: $font-xs;
    color: #999;
  }

  // ── FAB ─────────────────────────────────────────────────
  &__fab-stack {
    position: fixed;
    right: 20rpx;
    bottom: calc(98px + 172rpx);
    display: flex;
    flex-direction: column;
    gap: 20rpx;
    z-index: 50;
  }
  &__fab {
    width: 88rpx;
    height: 88rpx;
    border-radius: 50%;
    background: #fff;
    box-shadow: 0 4rpx 24rpx rgba(0,0,0,0.1);
    display: flex;
    align-items: center;
    justify-content: center;
  }
  &__fab-icon { font-size: $font-xl; }
}
</style>
