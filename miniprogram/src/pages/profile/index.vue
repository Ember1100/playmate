<template>
  <view class="profile">
    <!-- 顶部标题栏 -->
    <view class="profile__header">
      <view class="profile__back-btn" @click="uni.navigateBack()">
        <text class="profile__back-icon">←</text>
      </view>
      <text class="profile__page-title">我的</text>
      <view class="profile__settings-btn"
        @click="uni.navigateTo({url:'/pages/profile/settings'})">
        <text class="profile__settings-icon">⚙️</text>
      </view>
    </view>

    <scroll-view scroll-y class="profile__scroll">
      <!-- 用户信息区 -->
      <view class="profile__user-area">
        <!-- 头像 + 信息 -->
        <view class="profile__avatar-row">
          <view class="profile__avatar">
            <image
              v-if="userStore.profile?.avatar_url"
              :src="userStore.profile.avatar_url"
              class="profile__avatar-img"
              mode="aspectFill"
            />
            <text v-else class="profile__avatar-placeholder">
              {{ userStore.profile?.username?.charAt(0) || '我' }}
            </text>
          </view>
          <view class="profile__user-info">
            <text class="profile__user-name">{{ userStore.profile?.username || '搭伴用户' }}</text>
            <view class="profile__user-level">
              <text>ID: {{ userStore.profile?.id?.slice(0,8) || '888888' }}</text>
              <view class="profile__level-tag">
                <text>会员等级 Lv.{{ userStore.stats?.level ?? 5 }}</text>
              </view>
            </view>
          </view>
        </view>

        <!-- 成长积分 -->
        <view class="profile__growth">
          <view class="profile__growth-item">
            <text class="profile__growth-value">{{ userStore.stats?.growth_value ?? 2850 }}</text>
            <text class="profile__growth-label">成长值</text>
          </view>
          <view class="profile__growth-item">
            <text class="profile__growth-value">{{ userStore.stats?.points ?? 158 }}</text>
            <text class="profile__growth-label">积分</text>
          </view>
          <view class="profile__growth-item">
            <text class="profile__growth-value">{{ userStore.stats?.collect_count ?? 89 }}</text>
            <text class="profile__growth-label">收藏数</text>
          </view>
        </view>

        <!-- 标签云 -->
        <view class="profile__tags">
          <view v-for="tag in userTags" :key="tag" class="profile__tag">
            <text>{{ tag }}</text>
          </view>
        </view>

        <!-- 成长宣言 -->
        <view class="profile__motto">
          <text>成长宣言：分享闲置，交换美好，让每一件物品都能继续发光发热！</text>
        </view>
      </view>

      <!-- 功能中心 -->
      <view class="profile__module">
        <view class="profile__module-title"><text>功能中心</text></view>
        <view class="profile__module-list">
          <view
            v-for="item in funcMenuItems"
            :key="item.label"
            class="profile__module-item"
            @click="uni.navigateTo({url:item.path})"
          >
            <view class="profile__item-left">
              <view class="profile__item-icon">
                <text class="profile__item-emoji">{{ item.emoji }}</text>
              </view>
              <text class="profile__item-label">{{ item.label }}</text>
            </view>
            <view class="profile__item-right">
              <view v-if="item.badge" class="profile__badge"><text>{{ item.badge }}</text></view>
              <text class="profile__item-arrow">›</text>
            </view>
          </view>
        </view>
      </view>

      <!-- 我参与的活动 -->
      <view class="profile__module">
        <view class="profile__module-title"><text>我参与的活动</text></view>
        <view class="profile__module-list">
          <view
            v-for="act in myActivities"
            :key="act.label"
            class="profile__module-item"
          >
            <view class="profile__item-left">
              <view class="profile__item-icon">
                <text class="profile__item-emoji">{{ act.emoji }}</text>
              </view>
              <text class="profile__item-label">{{ act.label }}</text>
            </view>
            <view class="profile__item-right">
              <view class="profile__badge" :class="`status-${act.statusType}`">
                <text>{{ act.status }}</text>
              </view>
              <text class="profile__item-arrow">›</text>
            </view>
          </view>
        </view>
      </view>

      <!-- 退出登录 -->
      <view class="profile__module profile__module--logout">
        <view class="profile__module-list">
          <view class="profile__module-item" @click="onLogout">
            <view class="profile__item-left">
              <view class="profile__item-icon profile__item-icon--logout">
                <text class="profile__item-emoji">🚪</text>
              </view>
              <text class="profile__logout-text">退出登录</text>
            </view>
            <view class="profile__item-right">
              <text class="profile__item-arrow">›</text>
            </view>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
  <PmTabBar :current="4" />
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useUserStore } from '../../store/user'
import PmTabBar from '@/components/PmTabBar.vue'

const userStore = useUserStore()

const userTags = ['文艺青年', '无敌干饭', '职业i人', '亚洲舞王']

const funcMenuItems = [
  { emoji: '🔔', label: '消息通知', path: '/pages/profile/notifications', badge: 2 },
  { emoji: '❤️', label: '收藏列表', path: '/pages/profile/collects',     badge: 0 },
  { emoji: '👥', label: '搭子管理', path: '/pages/buddy/candidates',      badge: 0 },
  { emoji: '📝', label: '学习笔记', path: '/pages/profile/notes',         badge: 0 },
  { emoji: '👑', label: '会员中心', path: '/pages/profile/member',        badge: 0 },
]

const myActivities = [
  { emoji: '📍', label: '红色教育基地',   status: '进行中', statusType: 'active' },
  { emoji: '📷', label: '古城小巷摄影',   status: '已完成', statusType: 'done' },
  { emoji: '☕', label: '周末咖啡读书会', status: '已报名', statusType: 'signed' },
]

function onLogout() {
  uni.showModal({
    title: '提示',
    content: '确定要退出登录吗？',
    success: ({ confirm }) => {
      if (confirm) userStore.logout()
    },
  })
}

onMounted(async () => {
  if (userStore.isLoggedIn) {
    await Promise.all([
      userStore.fetchProfile().catch(() => {}),
      userStore.fetchStats().catch(() => {}),
    ])
  }
})
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.profile {
  min-height: 100vh;
  background: $color-bg-warm;
  display: flex;
  flex-direction: column;

  // 顶部标题栏
  &__header {
    display: flex;
    align-items: center;
    gap: 24rpx;
    padding: 30rpx;
    background: $color-bg-warm;
  }
  &__back-btn {
    width: 72rpx; height: 72rpx;
    border-radius: 50%;
    background: $color-bg-warm;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  &__back-icon { font-size: $font-xl; color: $color-primary; }
  &__page-title {
    font-size: $font-2xl;
    font-weight: 700;
    color: $color-text;
    flex: 1;
    text-align: center;
  }
  &__settings-btn {
    width: 72rpx; height: 72rpx;
    border-radius: 50%;
    background: $color-bg-warm;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  &__settings-icon { font-size: $font-xl; }

  &__scroll {
    flex: 1;
    padding: 0 30rpx 30rpx;
  }

  // 用户信息区
  &__user-area {
    padding: 0 0 32rpx;
    margin-bottom: 32rpx;
  }
  &__avatar-row {
    display: flex;
    align-items: center;
    gap: 32rpx;
    margin-bottom: 0;
  }
  &__avatar {
    width: 128rpx; height: 128rpx;
    border-radius: 50%;
    background: $color-primary-light;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    flex-shrink: 0;
  }
  &__avatar-img { width: 100%; height: 100%; }
  &__avatar-placeholder {
    font-size: $font-3xl;
    font-weight: 600;
    color: $color-text;
  }
  &__user-info { flex: 1; }
  &__user-name {
    font-size: $font-xl;
    font-weight: 700;
    color: $color-text;
    display: block;
    margin-bottom: 8rpx;
  }
  &__user-level {
    display: flex;
    align-items: center;
    gap: 12rpx;
    font-size: $font-base;
    color: $color-text-gray;
  }
  &__level-tag {
    background: $color-primary;
    color: #fff;
    padding: 4rpx 16rpx;
    border-radius: 20rpx;
    font-size: $font-xs;
  }

  // 成长值
  &__growth {
    display: flex;
    justify-content: space-around;
    padding: 40rpx 30rpx;
    background: $color-bg-white;
    border-radius: 40rpx;
    box-shadow: $shadow-soft;
    margin-top: 40rpx;
    margin-bottom: 24rpx;
  }
  &__growth-item {
    text-align: center;
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 8rpx;
  }
  &__growth-value {
    font-size: $font-2xl;
    font-weight: 700;
    color: $color-primary;
  }
  &__growth-label { font-size: $font-base; color: $color-text-mid; }

  // 标签云
  &__tags {
    display: flex;
    flex-wrap: wrap;
    gap: 12rpx;
    margin-bottom: 24rpx;
  }
  &__tag {
    background: $color-primary;
    color: #fff;
    padding: 8rpx 20rpx;
    border-radius: 200rpx;
    font-size: $font-xs;
  }

  // 成长宣言
  &__motto {
    background: $color-bg-white;
    border-radius: 24rpx;
    padding: 20rpx 30rpx;
    font-size: $font-base;
    line-height: 1.5;
    color: $color-text-mid;
    box-shadow: $shadow-soft;
  }

  // 功能模块
  &__module {
    margin: 24rpx 0 32rpx;
    background: $color-bg-white;
    border-radius: 40rpx;
    box-shadow: $shadow-soft;
    overflow: hidden;
    &--logout { margin-bottom: 80rpx; }
  }
  &__module-title {
    padding: 32rpx 30rpx;
    font-size: $font-base;
    font-weight: 600;
    color: $color-text-deep;
    border-bottom: 2rpx solid $color-border;
  }
  &__module-list {}
  &__module-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 32rpx 30rpx;
    border-bottom: 2rpx solid $color-border;
    font-size: $font-md;
    color: $color-text-deep;
    &:last-child { border-bottom: none; }
  }
  &__item-left {
    display: flex;
    align-items: center;
    gap: 24rpx;
  }
  &__item-icon {
    width: 48rpx; height: 48rpx;
    border-radius: 12rpx;
    background: $color-primary-light;
    display: flex;
    align-items: center;
    justify-content: center;
    &--logout { background: #f5eaea; }
  }
  &__item-emoji { font-size: $font-lg; }
  &__item-label { font-size: $font-md; color: $color-text-deep; }
  &__item-right {
    display: flex;
    align-items: center;
    gap: 12rpx;
    color: $color-text-gray;
  }
  &__badge {
    background: $color-primary;
    color: #fff;
    font-size: $font-xs;
    padding: 2rpx 12rpx;
    border-radius: 20rpx;
    &.status-active { background: $color-primary; }
    &.status-done   { background: $color-text-gray; }
    &.status-signed { background: $color-success; }
  }
  &__item-arrow { font-size: $font-lg; color: #ccc; opacity: 0.8; }
  &__logout-text { font-size: $font-md; color: #e88888; }
}
</style>
