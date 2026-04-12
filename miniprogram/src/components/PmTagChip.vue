<template>
  <text class="pm-tag" :class="`pm-tag--${variant}`">
    <slot />
  </text>
</template>

<script setup lang="ts">
withDefaults(defineProps<{
  variant?: 'primary' | 'secondary' | 'gray'
}>(), { variant: 'primary' })
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.pm-tag {
  display: inline-block;
  padding: 4rpx 16rpx;
  border-radius: $radius-tag;
  font-size: $font-xs;

  &--primary {
    background-color: rgba(255, 122, 0, 0.1);
    color: $color-primary;
  }
  &--secondary {
    background-color: rgba(93, 202, 165, 0.12);
    color: $color-secondary;
  }
  &--gray {
    background-color: #F0EEE8;
    color: $color-text-gray;
  }
}
</style>
