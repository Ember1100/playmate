<template>
  <view class="register">
    <!-- 自定义导航栏返回按钮 -->
    <view class="register__nav">
      <view class="register__back" @click="onBack">
        <text class="register__back-icon">‹</text>
      </view>
    </view>

    <scroll-view scroll-y class="register__scroll">
      <view class="register__body">
        <view class="register__gap-16" />
        <text class="register__title">创建账号</text>
        <view class="register__gap-8" />
        <text class="register__subtitle">加入搭伴，认识有趣的人</text>
        <view class="register__gap-36" />

        <!-- 昵称 -->
        <view class="register__field">
          <text class="register__field-icon">🪪</text>
          <input
            v-model="username"
            class="register__field-input"
            type="text"
            maxlength="32"
            placeholder="昵称"
            placeholder-class="register__placeholder"
          />
        </view>
        <view class="register__gap-12" />

        <!-- 邮箱 -->
        <view class="register__field">
          <text class="register__field-icon">✉</text>
          <input
            v-model="email"
            class="register__field-input"
            type="text"
            placeholder="邮箱"
            placeholder-class="register__placeholder"
          />
        </view>
        <view class="register__gap-12" />

        <!-- 密码 -->
        <view class="register__field">
          <text class="register__field-icon">🔒</text>
          <input
            v-model="password"
            class="register__field-input"
            :password="obscurePassword"
            placeholder="密码（至少6位）"
            placeholder-class="register__placeholder"
          />
          <text class="register__field-toggle" @click="obscurePassword = !obscurePassword">
            {{ obscurePassword ? '👁' : '🙈' }}
          </text>
        </view>
        <view class="register__gap-32" />

        <!-- 注册按钮 -->
        <PmButton block :loading="loading" @click="onRegister">注册</PmButton>
        <view class="register__gap-20" />

        <!-- 登录跳转 -->
        <view class="register__link-row">
          <text class="register__link-label">已有账号？</text>
          <text class="register__link-btn" @click="onBack">立即登录</text>
        </view>

        <view class="register__gap-40" />
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { emailRegister } from '../../api/auth'
import { useUserStore } from '../../store/user'
import PmButton from '../../components/PmButton.vue'

const userStore = useUserStore()

const username = ref('')
const email = ref('')
const password = ref('')
const obscurePassword = ref(true)
const loading = ref(false)

function onBack() {
  uni.navigateBack()
}

async function onRegister() {
  if (!username.value) {
    uni.showToast({ title: '请输入昵称', icon: 'none' })
    return
  }
  if (username.value.length < 2) {
    uni.showToast({ title: '昵称至少2个字符', icon: 'none' })
    return
  }
  if (!email.value || !email.value.includes('@')) {
    uni.showToast({ title: '请输入有效的邮箱', icon: 'none' })
    return
  }
  if (!password.value || password.value.length < 6) {
    uni.showToast({ title: '密码至少6位', icon: 'none' })
    return
  }
  loading.value = true
  try {
    const res = await emailRegister({
      username: username.value.trim(),
      email: email.value.trim(),
      password: password.value,
    })
    userStore.setTokens(res.access_token, res.refresh_token)
    userStore.fetchProfile()
    if (res.is_new_user) {
      uni.navigateTo({ url: '/pages/auth/questionnaire' })
    } else {
      uni.switchTab({ url: '/pages/buddy/index' })
    }
  } catch (e: any) {
    uni.showToast({ title: e.message || '注册失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.register {
  min-height: 100vh;
  background-color: $color-bg-white;

  // ── 导航栏 ──────────────────────────────
  &__nav {
    height: 88rpx;
    display: flex;
    align-items: center;
    padding: 0 24rpx;
  }
  &__back {
    width: 64rpx;
    height: 64rpx;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  &__back-icon {
    font-size: 52rpx;
    color: $color-text;
    line-height: 1;
    font-weight: 300;
  }

  &__scroll {
    height: calc(100vh - 88rpx);
  }

  &__body {
    display: flex;
    flex-direction: column;
    padding: 0 56rpx;
  }

  // ── 标题 ────────────────────────────────
  &__title {
    font-size: $font-3xl;
    font-weight: 700;
    color: $color-text;
  }
  &__subtitle {
    font-size: $font-md;
    color: $color-text-gray;
  }

  // ── 间距辅助 ────────────────────────────
  &__gap-8  { height: 8rpx; }
  &__gap-12 { height: 12rpx; }
  &__gap-16 { height: 16rpx; }
  &__gap-20 { height: 20rpx; }
  &__gap-32 { height: 32rpx; }
  &__gap-36 { height: 36rpx; }
  &__gap-40 { height: 40rpx; }

  // ── 输入框 ──────────────────────────────
  &__field {
    width: 100%;
    height: 88rpx;
    background-color: $color-bg;
    border-radius: $radius-button;
    display: flex;
    align-items: center;
    padding: 0 24rpx;
    box-sizing: border-box;
  }
  &__field-icon {
    font-size: 36rpx;
    margin-right: 16rpx;
    flex-shrink: 0;
  }
  &__field-input {
    flex: 1;
    font-size: $font-base;
    color: $color-text;
  }
  &__field-toggle {
    font-size: 32rpx;
    padding: 8rpx;
    flex-shrink: 0;
  }

  // ── 链接行 ──────────────────────────────
  &__link-row {
    display: flex;
    align-items: center;
    justify-content: center;
  }
  &__link-label {
    font-size: $font-base;
    color: $color-text-gray;
  }
  &__link-btn {
    font-size: $font-base;
    color: $color-primary;
    font-weight: 600;
    padding: 8rpx 8rpx;
  }
}

.register__placeholder {
  color: $color-text-hint;
}
</style>
