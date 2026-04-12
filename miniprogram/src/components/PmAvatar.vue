<template>
  <image
    class="pm-avatar"
    :src="src || defaultAvatar"
    :style="sizeStyle"
    mode="aspectFill"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{
  src?: string | null
  size?: number   // rpx，默认 80
}>(), {
  size: 80,
})

const defaultAvatar = '/static/icons/default-avatar.png'

const sizeStyle = computed(() => ({
  width: `${props.size}rpx`,
  height: `${props.size}rpx`,
  borderRadius: '50%',
}))
</script>

<style lang="scss" scoped>
.pm-avatar {
  flex-shrink: 0;
  background-color: #F0EEE8;
}
</style>
