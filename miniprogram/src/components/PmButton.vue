<template>
  <button
    class="pm-btn"
    :class="[`pm-btn--${type}`, { 'pm-btn--disabled': disabled, 'pm-btn--block': block }]"
    :disabled="disabled || loading"
    :open-type="openType"
    @click="$emit('click')"
  >
    <text v-if="loading" class="pm-btn__loading">…</text>
    <slot v-else />
  </button>
</template>

<script setup lang="ts">
withDefaults(defineProps<{
  type?: 'primary' | 'outline' | 'ghost' | 'danger'
  disabled?: boolean
  loading?: boolean
  block?: boolean
  openType?: string
}>(), {
  type: 'primary',
})

defineEmits<{ click: [] }>()
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.pm-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 80rpx;
  padding: 0 40rpx;
  border-radius: $radius-button;
  font-size: $font-base;
  font-weight: 500;
  border: none;

  &::after { border: none; }

  &--primary {
    background-color: $color-primary;
    color: #FFFFFF;
  }
  &--outline {
    background-color: transparent;
    border: 2rpx solid $color-primary;
    color: $color-primary;
  }
  &--ghost {
    background-color: transparent;
    color: $color-text;
  }
  &--danger {
    background-color: $color-danger;
    color: #FFFFFF;
  }
  &--disabled {
    opacity: 0.4;
  }
  &--block {
    width: 100%;
  }
}
</style>
