<template>
  <view class="pm-empty">
    <image class="pm-empty__icon" src="/static/icons/empty.png" mode="aspectFit" />
    <text class="pm-empty__text">{{ text }}</text>
  </view>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ text?: string }>(), { text: '暂无内容' })
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.pm-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80rpx 0;

  &__icon {
    width: 160rpx;
    height: 160rpx;
    margin-bottom: 24rpx;
    opacity: 0.4;
  }
  &__text {
    font-size: $font-sm;
    color: $color-text-hint;
  }
}
</style>
