<template>
  <view class="tab-bar">
    <view
      v-for="(tab, i) in tabs"
      :key="i"
      class="tab-bar__item"
      @click="onTap(i)"
    >
      <text class="tab-bar__icon" :class="{ 'tab-bar__icon--active': selected === i }">
        {{ tab.icon }}
      </text>
      <text class="tab-bar__label" :class="{ 'tab-bar__label--active': selected === i }">
        {{ tab.text }}
      </text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const tabs = [
  { icon: '💬', text: '圈子', path: '/pages/circle/index' },
  { icon: '🏪', text: '集市', path: '/pages/market/index' },
  { icon: '👥', text: '搭子', path: '/pages/buddy/index' },
  { icon: '🎉', text: '趣玩', path: '/pages/fun/index' },
  { icon: '👤', text: '我的', path: '/pages/profile/index' },
]

const selected = ref(0)

// 由各 Tab 页的 onShow 通过 getTabBar().setIndex(n) 调用
function setIndex(index: number) {
  selected.value = index
}

defineExpose({ setIndex })

function onTap(index: number) {
  selected.value = index
  uni.switchTab({ url: tabs[index].path })
}
</script>

<style lang="scss">
@import '@/uni.scss';

.tab-bar {
  display: flex;
  height: 98px;
  background-color: #FFFFFF;
  border-top: 1px solid $color-border-warm;
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  // 兼容 iPhone 底部安全区
  padding-bottom: env(safe-area-inset-bottom);
  height: calc(98px + env(safe-area-inset-bottom));
  box-sizing: border-box;

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
    opacity: 0.5;
    transition: opacity 0.15s;

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
