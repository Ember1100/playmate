<template>
  <view class="login">
    <scroll-view scroll-y class="login__scroll">
      <view class="login__body">

        <!-- Logo -->
        <view class="login__logo-box">
          <text class="login__logo-text">搭</text>
        </view>
        <view class="login__gap-24" />

        <text class="login__title">欢迎来到搭伴</text>
        <view class="login__gap-8" />
        <text class="login__subtitle">遇见有趣的灵魂</text>
        <view class="login__gap-48" />

        <!-- 邮箱 -->
        <view class="login__field">
          <text class="login__field-icon">✉</text>
          <input
            v-model="email"
            class="login__field-input"
            type="text"
            placeholder="手机号 / 邮箱"
            placeholder-class="login__placeholder"
          />
        </view>
        <view class="login__gap-12" />

        <!-- 密码 -->
        <view class="login__field">
          <text class="login__field-icon">🔒</text>
          <input
            v-model="password"
            class="login__field-input"
            :password="obscurePassword"
            placeholder="密码"
            placeholder-class="login__placeholder"
          />
          <text class="login__field-toggle" @click="obscurePassword = !obscurePassword">
            {{ obscurePassword ? '👁' : '🙈' }}
          </text>
        </view>
        <view class="login__gap-28" />

        <!-- 登录按钮 -->
        <PmButton block :loading="loading" @click="onLogin">登录</PmButton>
        <view class="login__gap-20" />

        <!-- 注册跳转 -->
        <view class="login__link-row">
          <text class="login__link-label">还没有账号？</text>
          <text class="login__link-btn" @click="goRegister">立即注册</text>
        </view>

        <view class="login__gap-32" />

        <!-- 其他登录方式 -->
        <view class="login__divider-row">
          <view class="login__divider-line" />
          <text class="login__divider-text">其他登录方式</text>
          <view class="login__divider-line" />
        </view>
        <view class="login__gap-20" />

        <view class="login__third-row">
          <!-- 微信 -->
          <view class="login__third-item" @click="onWechatLogin">
            <view class="login__third-circle login__third-circle--wechat">
              <text class="login__third-circle-icon">微</text>
            </view>
            <text class="login__third-label">微信</text>
          </view>
          <!-- 手机号 -->
          <view class="login__third-item" @click="showSmsModal = true">
            <view class="login__third-circle">
              <text class="login__third-circle-icon">📱</text>
            </view>
            <text class="login__third-label">手机号</text>
          </view>
        </view>

        <view class="login__gap-40" />
      </view>
    </scroll-view>

    <!-- 手机号验证码弹层 -->
    <view v-if="showSmsModal" class="modal-mask" @click.self="showSmsModal = false">
      <view class="modal">
        <text class="modal__title">手机号登录</text>
        <input
          v-model="phone"
          class="modal__input"
          type="number"
          maxlength="11"
          placeholder="请输入手机号"
          placeholder-class="login__placeholder"
        />
        <view class="modal__sms-row">
          <input
            v-model="smsCode"
            class="modal__input modal__input--sms"
            type="number"
            maxlength="6"
            placeholder="验证码"
            placeholder-class="login__placeholder"
          />
          <button
            class="modal__send-btn"
            :disabled="countdown > 0 || sending"
            @click="onSendSms"
          >
            {{ countdown > 0 ? `${countdown}s` : '获取验证码' }}
          </button>
        </view>
        <PmButton block :loading="smsLoading" @click="onPhoneLogin">登录 / 注册</PmButton>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { emailLogin, wechatLogin, sendSmsCode, verifySmsCode } from '../../api/auth'
import { useUserStore } from '../../store/user'
import PmButton from '../../components/PmButton.vue'

const userStore = useUserStore()

// 邮箱登录
const email = ref('')
const password = ref('')
const obscurePassword = ref(true)
const loading = ref(false)

// 手机号弹层
const showSmsModal = ref(false)
const phone = ref('')
const smsCode = ref('')
const countdown = ref(0)
const sending = ref(false)
const smsLoading = ref(false)

function goRegister() {
  uni.navigateTo({ url: '/pages/auth/register' })
}

function afterLogin(res: { access_token: string; refresh_token: string; is_new_user: boolean }) {
  userStore.setTokens(res.access_token, res.refresh_token)
  userStore.fetchProfile()
  if (res.is_new_user) {
    uni.navigateTo({ url: '/pages/auth/questionnaire' })
  } else {
    uni.switchTab({ url: '/pages/buddy/index' })
  }
}

async function onLogin() {
  if (!email.value || !password.value) {
    uni.showToast({ title: '请填写完整', icon: 'none' })
    return
  }
  loading.value = true
  try {
    const res = await emailLogin(email.value.trim(), password.value)
    afterLogin(res)
  } catch (e: any) {
    uni.showToast({ title: e.message || '登录失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

async function onWechatLogin() {
  try {
    const { code } = await new Promise<{ code: string }>((resolve, reject) =>
      wx.login({ success: (r) => resolve({ code: r.code }), fail: reject })
    )
    const res = await wechatLogin(code)
    afterLogin(res)
  } catch (e: any) {
    uni.showToast({ title: e.message || '微信登录失败', icon: 'none' })
  }
}

async function onSendSms() {
  if (!phone.value || phone.value.length !== 11) {
    uni.showToast({ title: '请输入正确的手机号', icon: 'none' })
    return
  }
  sending.value = true
  try {
    await sendSmsCode(phone.value)
    countdown.value = 60
    const timer = setInterval(() => {
      countdown.value--
      if (countdown.value <= 0) clearInterval(timer)
    }, 1000)
    uni.showToast({ title: '验证码已发送', icon: 'success' })
  } catch (e: any) {
    uni.showToast({ title: e.message || '发送失败', icon: 'none' })
  } finally {
    sending.value = false
  }
}

async function onPhoneLogin() {
  if (!phone.value || !smsCode.value) {
    uni.showToast({ title: '请填写完整', icon: 'none' })
    return
  }
  smsLoading.value = true
  try {
    const res = await verifySmsCode(phone.value, smsCode.value)
    afterLogin(res)
  } catch (e: any) {
    uni.showToast({ title: e.message || '登录失败', icon: 'none' })
  } finally {
    smsLoading.value = false
  }
}
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.login {
  min-height: 100vh;
  background-color: $color-bg-white;

  &__scroll {
    height: 100vh;
  }

  &__body {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 0 56rpx;
    padding-top: 128rpx;
  }

  // ── Logo ────────────────────────────────
  &__logo-box {
    width: 144rpx;
    height: 144rpx;
    background-color: $color-primary;
    border-radius: 36rpx;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  &__logo-text {
    font-size: 72rpx;
    color: #FFFFFF;
    font-weight: 700;
    line-height: 1;
  }

  // ── 标题 ────────────────────────────────
  &__title {
    font-size: $font-3xl;
    font-weight: 700;
    color: $color-text;
    text-align: center;
  }
  &__subtitle {
    font-size: $font-md;
    color: $color-text-gray;
    text-align: center;
  }

  // ── 间距辅助 ────────────────────────────
  &__gap-8  { height: 8rpx; }
  &__gap-12 { height: 12rpx; }
  &__gap-20 { height: 20rpx; }
  &__gap-24 { height: 24rpx; }
  &__gap-28 { height: 28rpx; }
  &__gap-32 { height: 32rpx; }
  &__gap-40 { height: 40rpx; }
  &__gap-48 { height: 48rpx; }

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

  // ── 分割线 ──────────────────────────────
  &__divider-row {
    width: 100%;
    display: flex;
    align-items: center;
    gap: 24rpx;
  }
  &__divider-line {
    flex: 1;
    height: 1rpx;
    background-color: $color-border;
  }
  &__divider-text {
    font-size: $font-sm;
    color: $color-text-gray;
    white-space: nowrap;
  }

  // ── 第三方登录 ──────────────────────────
  &__third-row {
    display: flex;
    justify-content: center;
    gap: 48rpx;
  }
  &__third-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12rpx;
  }
  &__third-circle {
    width: 104rpx;
    height: 104rpx;
    border-radius: 50%;
    border: 2rpx solid $color-border;
    background-color: $color-bg;
    display: flex;
    align-items: center;
    justify-content: center;
    &--wechat {
      background-color: #07C160;
      border-color: #07C160;
    }
  }
  &__third-circle-icon {
    font-size: 44rpx;
    line-height: 1;
    color: #FFFFFF;
  }
  &__third-label {
    font-size: $font-sm;
    color: $color-text-gray;
  }
}

.login__placeholder {
  color: $color-text-hint;
}

// ── 手机号弹层 ──────────────────────────────────────────────────────────
.modal-mask {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: flex-end;
  z-index: 100;
}

.modal {
  width: 100%;
  background: #FFFFFF;
  border-radius: 32rpx 32rpx 0 0;
  padding: 48rpx 40rpx 80rpx;
  box-sizing: border-box;

  &__title {
    font-size: $font-lg;
    font-weight: 600;
    color: $color-text;
    display: block;
    margin-bottom: 40rpx;
  }
  &__input {
    width: 100%;
    height: 88rpx;
    border: 2rpx solid $color-border;
    border-radius: $radius-button;
    padding: 0 24rpx;
    font-size: $font-base;
    margin-bottom: 24rpx;
    box-sizing: border-box;
  }
  &__sms-row {
    display: flex;
    gap: 16rpx;
    margin-bottom: 32rpx;
  }
  &__input--sms {
    flex: 1;
    margin-bottom: 0;
  }
  &__send-btn {
    width: 200rpx;
    height: 88rpx;
    background-color: $color-bg;
    border: 2rpx solid $color-primary;
    color: $color-primary;
    border-radius: $radius-button;
    font-size: $font-sm;
    white-space: nowrap;
    &::after { border: none; }
    &[disabled] { opacity: 0.5; }
  }
}
</style>
