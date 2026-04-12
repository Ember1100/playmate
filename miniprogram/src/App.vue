<script setup lang="ts">
import { onLaunch, onShow } from '@dcloudio/uni-app'
import { useUserStore } from './store/user'

onLaunch(() => {
  const userStore = useUserStore()
  const token = uni.getStorageSync('access_token')
  if (token) {
    userStore.fetchProfile().catch(() => {
      // token 失效，跳登录
      uni.navigateTo({ url: '/pages/auth/login' })
    })
  } else {
    uni.navigateTo({ url: '/pages/auth/login' })
  }
})

onShow(() => {})
</script>

<style lang="scss">
@import '@/uni.scss';

page {
  background-color: $color-bg;
  color: $color-text;
  font-size: $font-base;
}

// 全局工具类
.text-primary { color: $color-primary; }
.text-gray    { color: $color-text-gray; }
.text-danger  { color: $color-danger; }
.bg-primary   { background-color: $color-primary; }
.bg-white     { background-color: $color-bg-white; }

.flex         { display: flex; }
.flex-center  { display: flex; align-items: center; justify-content: center; }
.flex-between { display: flex; align-items: center; justify-content: space-between; }
.flex-col     { display: flex; flex-direction: column; }

.card {
  background-color: $color-bg-white;
  border-radius: $radius-card;
  padding: $spacing-md;
}
</style>
