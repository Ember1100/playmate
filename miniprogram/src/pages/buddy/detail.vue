<template>
  <view class="detail">
    <!-- 个人信息头部 -->
    <view class="detail__header">
      <image
        class="detail__avatar"
        src="https://picsum.photos/seed/user_ya/200/200"
        mode="aspectFill"
      />
      <view class="detail__info">
        <text class="detail__name">阿雅</text>
        <view class="detail__tags">
          <view class="detail__chip secondary">
            <text>顺应搭子</text>
          </view>
          <view class="detail__chip verified">
            <text>✓ 实名认证</text>
          </view>
        </view>
        <view class="detail__credit">
          <text class="detail__credit-star">★</text>
          <text class="detail__credit-label">信用分：</text>
          <text class="detail__credit-score">920</text>
          <view class="detail__credit-badge">
            <text class="detail__credit-badge-text">极佳</text>
          </view>
        </view>
      </view>
    </view>

    <!-- 个人简介 -->
    <view class="detail__bio">
      <!-- 引语 -->
      <view class="detail__bio-quote">
        <text class="detail__bio-quote-mark">"</text>
        <text class="detail__bio-quote-text">用专业与爱心，守护毛孩子的健康成长</text>
      </view>
      <!-- 遛宠搭子标题 -->
      <view class="detail__section-title">
        <view class="detail__section-bar" />
        <text>遛宠搭子</text>
      </view>
      <!-- 简介文字 -->
      <text class="detail__bio-text">
        宠物陪伴师，宠龄5年，熟悉各类宠物习性，特别是犬类。每周5~7年，熟悉各类宠物习性，特别是犬类，以及猫咪行为学。因此立志成为一名专业的宠物服务者，作为特定宠物陪伴师，我带着与各种性格的孩子打磨，能够敏锐把握宠物的情绪和需求，提供专业、贴心的服务。
      </text>
      <!-- 擅长领域 -->
      <view class="detail__bio-block">
        <view class="detail__bio-label">
          <text>擅长领域</text>
        </view>
        <text class="detail__bio-content">宠物训练、家庭护理、宠物行为评估</text>
      </view>
      <!-- 服务方式 -->
      <view class="detail__bio-block">
        <view class="detail__bio-label">
          <text>服务方式</text>
        </view>
        <text class="detail__bio-content">帮孩子散步、分享养宠经验、宠物社交不尴尬</text>
      </view>
      <!-- 服务承诺 -->
      <view class="detail__bio-block">
        <view class="detail__bio-label">
          <text>服务承诺</text>
        </view>
        <text class="detail__bio-content">专业照料·科学喂养·安全第一</text>
      </view>
    </view>

    <!-- Tab 栏 -->
    <view class="detail__tab-bar">
      <view
        v-for="(tab, i) in tabs"
        :key="tab"
        class="detail__tab"
        :class="{ active: activeTab === i }"
        @click="activeTab = i"
      >
        <text>{{ tab }}</text>
      </view>
    </view>

    <!-- Tab 内容 -->
    <scroll-view scroll-y class="detail__content">
      <!-- 养宠实用干货 -->
      <view v-if="activeTab === 0" class="detail__placeholder">
        <text class="detail__placeholder-icon">⏳</text>
        <text class="detail__placeholder-text">养宠实用干货 内容即将上线</text>
      </view>

      <!-- 遛宠搭子陪伴 -->
      <view v-if="activeTab === 1" class="detail__service">
        <!-- 大图 -->
        <image
          class="detail__service-cover"
          src="https://picsum.photos/seed/golden/800/400"
          mode="aspectFill"
        />
        <!-- 核心服务内容 -->
        <view class="detail__card">
          <view class="detail__card-header">
            <text class="detail__card-icon" style="color: #5DCAA5">🐾</text>
            <text class="detail__card-title">核心服务内容</text>
          </view>
          <view class="detail__card-body">
            <view class="detail__bullet">
              <view class="detail__bullet-dot" />
              <text>遛宠陪伴：每日定时遛弯，科学运动，快乐社交</text>
            </view>
            <view class="detail__bullet">
              <view class="detail__bullet-dot" />
              <text>生活协助：上门喂食换水，清洁环境、梳毛护理</text>
            </view>
            <view class="detail__bullet">
              <view class="detail__bullet-dot" />
              <text>专属定制：根据宠物性格定制专属陪伴方案</text>
            </view>
          </view>
        </view>
        <!-- 超值体验套餐 -->
        <view class="detail__card">
          <view class="detail__card-header">
            <text class="detail__card-icon" style="color: #FF7A00">🏷️</text>
            <text class="detail__card-title">超值体验套餐</text>
          </view>
          <view class="detail__packages">
            <view class="detail__package">
              <text class="detail__package-label">体验单次</text>
              <text class="detail__package-price">¥19.9</text>
              <text class="detail__package-desc">单次遛狗</text>
            </view>
            <view class="detail__package">
              <text class="detail__package-label">周套餐</text>
              <text class="detail__package-price">¥80</text>
              <text class="detail__package-desc">每周5次</text>
            </view>
            <view class="detail__package">
              <text class="detail__package-label">月套餐</text>
              <text class="detail__package-price">¥300</text>
              <text class="detail__package-desc">每月20次</text>
            </view>
          </view>
        </view>
        <!-- 用户好评 -->
        <view class="detail__card">
          <view class="detail__card-header">
            <text class="detail__card-icon" style="color: #FF7A00">💬</text>
            <text class="detail__card-title">用户好评</text>
          </view>
          <view class="detail__review-preview">
            <text class="detail__review-quote">"非常专业，狗狗很喜欢她，推荐！"</text>
            <view class="detail__review-meta">
              <view class="detail__review-avatar">
                <text>👤</text>
              </view>
              <text class="detail__review-name">宠主小李</text>
              <view class="detail__review-stars">
                <text v-for="n in 5" :key="n" class="detail__review-star">★</text>
              </view>
            </view>
          </view>
        </view>
        <!-- 服务安全保障 -->
        <view class="detail__card">
          <view class="detail__card-header">
            <text class="detail__card-icon" style="color: #5DCAA5">🛡️</text>
            <text class="detail__card-title">服务安全保障</text>
          </view>
          <view class="detail__card-body">
            <view class="detail__bullet">
              <text style="color: #5DCAA5; margin-right: 16rpx">✓</text>
              <text>实名认证·全程视频反馈·100% 履约承诺</text>
            </view>
          </view>
        </view>
        <!-- 本月服务日程 -->
        <view class="detail__card">
          <view class="detail__card-header">
            <text class="detail__card-icon" style="color: #FF7A00">📅</text>
            <text class="detail__card-title">本月服务日程</text>
          </view>
          <view class="detail__calendar">
            <view
              v-for="day in 31"
              :key="day"
              class="detail__cal-cell"
            >
              <text class="detail__cal-day" :class="calClass(day)">{{ day }}</text>
              <view class="detail__cal-status" :class="calClass(day)">
                <text>{{ calLabel(day) }}</text>
              </view>
            </view>
          </view>
        </view>
        <view style="height: 160rpx" />
      </view>

      <!-- 宠物顾问咨询 -->
      <view v-if="activeTab === 2" class="detail__placeholder">
        <text class="detail__placeholder-icon">⏳</text>
        <text class="detail__placeholder-text">宠物顾问咨询 内容即将上线</text>
      </view>

      <!-- 用户评价 -->
      <view v-if="activeTab === 3" class="detail__reviews">
        <view
          v-for="r in reviews"
          :key="r.name"
          class="detail__review-card"
        >
          <view class="detail__review-top">
            <view class="detail__review-uavatar">
              <text>👤</text>
            </view>
            <view class="detail__review-info">
              <text class="detail__review-uname">{{ r.name }}</text>
              <view class="detail__review-stars">
                <text
                  v-for="n in 5"
                  :key="n"
                  class="detail__review-star"
                  :class="{ empty: n > r.rating }"
                >★</text>
              </view>
            </view>
          </view>
          <text class="detail__review-comment">{{ r.comment }}</text>
        </view>
        <view style="height: 160rpx" />
      </view>
    </scroll-view>

    <!-- 底部操作栏 -->
    <view class="detail__bottom">
      <view class="detail__btn-outline" @click="onMessage">
        <text class="detail__btn-icon">💬</text>
        <text class="detail__btn-text">私信</text>
      </view>
      <view class="detail__btn-primary" @click="onInvite">
        <text class="detail__btn-icon">📅</text>
        <text class="detail__btn-text">发起邀约</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const activeTab = ref(1) // 默认选中"遛宠搭子陪伴"

const tabs = ['养宠实用干货', '遛宠搭子陪伴', '宠物顾问咨询', '用户评价']

// 日历状态 0=可约 1=已满 2=已预约
const calStatusMap: Record<number, number> = {
  1: 1, 2: 1, 3: 0, 4: 0, 5: 2, 6: 0, 7: 2,
  8: 1, 9: 0, 10: 0, 11: 2, 12: 2, 13: 0, 14: 2,
  15: 1, 16: 0, 17: 0, 18: 0, 19: 2, 20: 2, 21: 2,
  22: 1, 23: 0, 24: 0, 25: 2, 26: 2, 27: 0, 28: 2,
  29: 0, 30: 2, 31: 1,
}

const reviews = [
  { name: '宠主小李', rating: 5, comment: '非常专业，狗狗很喜欢她！每次遛完都很开心，强烈推荐！' },
  { name: '铲屎官小王', rating: 5, comment: '服务很贴心，每次都准时，还会发照片给我们，很放心。' },
  { name: '狗主人阿豪', rating: 4, comment: '整体不错，专业度高，就是偶尔会迟到一点点，但服务质量很好。' },
  { name: '猫咪妈妈', rating: 5, comment: '我家猫咪超喜欢阿雅，而且每次都整理得干干净净再走！' },
]

function calClass(day: number): string {
  const s = calStatusMap[day] ?? 0
  return ['available', 'full', 'booked'][s]
}

function calLabel(day: number): string {
  const s = calStatusMap[day] ?? 0
  return ['可约', '已满', '已预约'][s]
}

function onMessage() {
  // TODO: 跳转私信
}

function onInvite() {
  // TODO: 发起邀约
}
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.detail {
  min-height: 100vh;
  background-color: $color-bg;
  display: flex;
  flex-direction: column;

  // ── 个人信息头部 ──────────────────────────────────────────
  &__header {
    display: flex;
    align-items: flex-start;
    gap: 28rpx;
    padding: 32rpx;
    background: #fff;
  }
  &__avatar {
    width: 172rpx;
    height: 172rpx;
    border-radius: $radius-card;
    flex-shrink: 0;
    background: #f5f5f5;
  }
  &__info {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 12rpx;
  }
  &__name {
    font-size: $font-xl;
    font-weight: 800;
    color: $color-text;
  }
  &__tags {
    display: flex;
    flex-wrap: wrap;
    gap: 12rpx;
  }
  &__chip {
    display: inline-flex;
    align-items: center;
    padding: 6rpx 16rpx;
    border-radius: 999rpx;
    font-size: $font-xs;
    font-weight: 600;

    &.secondary {
      background: #5DCAA5;
      color: #fff;
    }
    &.verified {
      background: #FFF0DC;
      color: #FF7A00;
      border: 2rpx solid #FF7A00;
    }
  }
  &__credit {
    display: flex;
    align-items: center;
    gap: 8rpx;
  }
  &__credit-star {
    color: #FF7A00;
    font-size: $font-md;
  }
  &__credit-label {
    font-size: $font-sm;
    color: #888780;
  }
  &__credit-score {
    font-size: $font-md;
    font-weight: 700;
    color: #FF7A00;
  }
  &__credit-badge {
    padding: 2rpx 12rpx;
    background: #FF7A00;
    border-radius: 999rpx;
  }
  &__credit-badge-text {
    font-size: $font-xs;
    color: #fff;
    font-weight: 600;
  }

  // ── 个人简介 ──────────────────────────────────────────
  &__bio {
    margin-top: 16rpx;
    padding: 32rpx;
    background: #fff;
  }
  &__bio-quote {
    display: flex;
    align-items: flex-start;
    gap: 8rpx;
    background: #f5f5f5;
    border-radius: 16rpx;
    padding: 20rpx 28rpx;
  }
  &__bio-quote-mark {
    font-size: $font-xl;
    color: #FF7A00;
    line-height: 1;
  }
  &__bio-quote-text {
    font-size: $font-sm;
    color: $color-text;
    font-style: italic;
    flex: 1;
  }
  &__section-title {
    display: flex;
    align-items: center;
    gap: 16rpx;
    margin-top: 28rpx;
    margin-bottom: 16rpx;
    font-size: $font-md;
    font-weight: 700;
    color: $color-text;
  }
  &__section-bar {
    width: 6rpx;
    height: 32rpx;
    background: #FF7A00;
    border-radius: 4rpx;
  }
  &__bio-text {
    font-size: $font-sm;
    color: #555;
    line-height: 1.6;
  }
  &__bio-block {
    display: flex;
    align-items: flex-start;
    gap: 16rpx;
    margin-top: 16rpx;
  }
  &__bio-label {
    padding: 4rpx 12rpx;
    border: 2rpx solid #FF7A00;
    border-radius: 8rpx;
    font-size: $font-xs;
    color: #FF7A00;
    font-weight: 600;
    flex-shrink: 0;
  }
  &__bio-content {
    font-size: $font-sm;
    color: #555;
    line-height: 1.5;
    flex: 1;
  }

  // ── Tab 栏 ──────────────────────────────────────────
  &__tab-bar {
    display: flex;
    background: #fff;
    border-bottom: 2rpx solid #eee;
    padding: 0 16rpx;
    overflow-x: auto;
    white-space: nowrap;
  }
  &__tab {
    padding: 20rpx 24rpx;
    font-size: $font-sm;
    color: #888780;
    flex-shrink: 0;
    position: relative;

    &.active {
      color: #FF7A00;
      font-weight: 700;

      &::after {
        content: '';
        position: absolute;
        bottom: 0;
        left: 50%;
        transform: translateX(-50%);
        width: 40rpx;
        height: 5rpx;
        background: #FF7A00;
        border-radius: 3rpx;
      }
    }
  }

  // ── Tab 内容 ──────────────────────────────────────────
  &__content {
    flex: 1;
    height: 0;
  }

  // 占位 Tab
  &__placeholder {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 120rpx 0;
    gap: 24rpx;
  }
  &__placeholder-icon {
    font-size: 96rpx;
    opacity: 0.3;
  }
  &__placeholder-text {
    font-size: $font-base;
    color: #888780;
  }

  // ── 遛宠搭子陪伴 Tab ──────────────────────────────────
  &__service {
    // wrapper
  }
  &__service-cover {
    width: 100%;
    height: 400rpx;
    display: block;
    background: #f5f5f5;
  }

  // 服务卡片
  &__card {
    background: #fff;
    padding: 28rpx 32rpx 32rpx;
  }
  &__card-header {
    display: flex;
    align-items: center;
    gap: 12rpx;
    margin-bottom: 24rpx;
  }
  &__card-icon {
    font-size: $font-lg;
  }
  &__card-title {
    font-size: $font-md;
    font-weight: 700;
    color: $color-text;
  }
  &__card-body {
    display: flex;
    flex-direction: column;
    gap: 12rpx;
  }

  // 列表项
  &__bullet {
    display: flex;
    align-items: flex-start;
    gap: 16rpx;
    font-size: $font-sm;
    color: #555;
    line-height: 1.6;
  }
  &__bullet-dot {
    width: 10rpx;
    height: 10rpx;
    border-radius: 50%;
    background: #FF7A00;
    margin-top: 14rpx;
    flex-shrink: 0;
  }

  // 套餐
  &__packages {
    display: flex;
    gap: 16rpx;
  }
  &__package {
    flex: 1;
    padding: 24rpx 16rpx;
    background: $color-bg;
    border-radius: 20rpx;
    border: 2rpx solid #FFD8A8;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8rpx;
  }
  &__package-label {
    font-size: $font-sm;
    color: #888780;
    font-weight: 500;
  }
  &__package-price {
    font-size: $font-xl;
    font-weight: 800;
    color: #FF7A00;
  }
  &__package-desc {
    font-size: $font-xs;
    color: #888780;
  }

  // 评价预览
  &__review-preview {
    padding: 24rpx;
    background: $color-bg;
    border-radius: 16rpx;
  }
  &__review-quote {
    font-size: $font-sm;
    color: $color-text;
    font-style: italic;
    line-height: 1.5;
    margin-bottom: 12rpx;
  }
  &__review-meta {
    display: flex;
    align-items: center;
    gap: 12rpx;
  }
  &__review-avatar {
    width: 44rpx;
    height: 44rpx;
    border-radius: 50%;
    background: #e0e0e0;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: $font-xs;
  }
  &__review-name {
    font-size: $font-sm;
    color: #888780;
  }
  &__review-stars {
    margin-left: auto;
    display: flex;
  }
  &__review-star {
    font-size: $font-sm;
    color: #FF7A00;

    &.empty {
      color: #ddd;
    }
  }

  // 日历
  &__calendar {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 12rpx 8rpx;
  }
  &__cal-cell {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4rpx;
  }
  &__cal-day {
    font-size: $font-sm;
    font-weight: 600;

    &.available { color: #5DCAA5; }
    &.full { color: #E24B4A; }
    &.booked { color: #FF7A00; }
  }
  &__cal-status {
    padding: 2rpx 6rpx;
    border-radius: 6rpx;
    font-size: 18rpx;
    font-weight: 500;

    &.available { background: #E8F8F2; color: #5DCAA5; }
    &.full { background: #FFEEEE; color: #E24B4A; }
    &.booked { background: #FFF0DC; color: #FF7A00; }
  }

  // ── 用户评价 Tab ──────────────────────────────────────────
  &__reviews {
    padding: 32rpx;
  }
  &__review-card {
    background: #fff;
    border-radius: $radius-card;
    padding: 28rpx;
    margin-bottom: 24rpx;
    box-shadow: 0 4rpx 12rpx rgba(0, 0, 0, 0.04);
  }
  &__review-top {
    display: flex;
    align-items: center;
    gap: 20rpx;
    margin-bottom: 20rpx;
  }
  &__review-uavatar {
    width: 68rpx;
    height: 68rpx;
    border-radius: 50%;
    background: #E8E6E0;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: $font-md;
  }
  &__review-info {
    display: flex;
    flex-direction: column;
    gap: 4rpx;
  }
  &__review-uname {
    font-size: $font-sm;
    font-weight: 600;
    color: $color-text;
  }
  &__review-comment {
    font-size: $font-sm;
    color: #555;
    line-height: 1.6;
  }

  // ── 底部操作栏 ──────────────────────────────────────────
  &__bottom {
    display: flex;
    gap: 24rpx;
    padding: 24rpx 32rpx;
    padding-bottom: calc(24rpx + env(safe-area-inset-bottom));
    background: #fff;
    border-top: 2rpx solid #eee;
  }
  &__btn-outline {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12rpx;
    padding: 24rpx 0;
    border: 2rpx solid #FF7A00;
    border-radius: 16rpx;
    background: #fff;
  }
  &__btn-primary {
    flex: 2;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12rpx;
    padding: 24rpx 0;
    border-radius: 16rpx;
    background: #FF7A00;
  }
  &__btn-icon {
    font-size: $font-md;
  }
  &__btn-text {
    font-size: $font-md;
    font-weight: 700;
  }
  &__btn-outline &__btn-text {
    color: #FF7A00;
  }
  &__btn-primary &__btn-text {
    color: #fff;
  }
}
</style>
