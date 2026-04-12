<template>
  <view class="pm-tab-bar">
    <view
      v-for="(tab, i) in tabs"
      :key="i"
      class="pm-tab-bar__item"
      @click="onTap(i)"
    >
      <text :class="['pm-tab-bar__icon', { 'pm-tab-bar__icon--active': current === i }]">
        {{ tab.icon }}
      </text>
      <text :class="['pm-tab-bar__label', { 'pm-tab-bar__label--active': current === i }]">
        {{ tab.text }}
      </text>
    </view>
  </view>
</template>

<script setup lang="ts">
defineProps<{ current: number }>()

const tabs = [
  { icon: '💬', text: '圈子', path: '/pages/circle/index' },
  { icon: '🏪', text: '集市', path: '/pages/market/index' },
  { icon: '👥', text: '搭子', path: '/pages/buddy/index' },
  { icon: '🎉', text: '趣玩', path: '/pages/fun/index' },
  { icon: '👤', text: '我的', path: '/pages/profile/index' },
]

function onTap(i: number) {
  uni.switchTab({ url: tabs[i].path })
}
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.pm-tab-bar {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  height: 98px;
  padding-bottom: env(safe-area-inset-bottom);
  box-sizing: content-box;
  background: #FFFFFF;
  border-top: 1px solid $color-border-warm;
  display: flex;

  &__item {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 4px;
  }

  &__icon {
    font-size: 44rpx;
    line-height: 1;
    filter: grayscale(100%);
    opacity: 0.45;

    &--active {
      filter: none;
      opacity: 1;
    }
  }

  &__label {
    font-size: 20rpx;
    color: $color-text-gray;
    line-height: 1;

    &--active {
      color: $color-primary;
      font-weight: 600;
    }
  }
}
</style>
