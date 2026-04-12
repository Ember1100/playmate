<template>
  <view v-if="show" class="pm-loading">
    <view class="pm-loading__spinner" />
    <text v-if="text" class="pm-loading__text">{{ text }}</text>
  </view>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ show?: boolean; text?: string }>(), { show: true })
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.pm-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40rpx;

  &__spinner {
    width: 48rpx;
    height: 48rpx;
    border: 4rpx solid $color-border;
    border-top-color: $color-primary;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }
  &__text {
    margin-top: 16rpx;
    font-size: $font-sm;
    color: $color-text-gray;
  }
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
