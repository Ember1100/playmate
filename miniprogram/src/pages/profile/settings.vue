<template>
  <view class="settings">
    <!-- 顶部标题 -->
    <view class="settings__header">
      <view class="settings__back" @click="uni.navigateBack()">
        <text class="settings__back-icon">←</text>
      </view>
      <text class="settings__title">设置</text>
    </view>

    <scroll-view scroll-y class="settings__scroll">
      <!-- 帮助与设置 -->
      <view class="settings__module">
        <view class="settings__module-list">
          <view
            v-for="item in settingItems"
            :key="item.label"
            class="settings__item"
            @click="onItemTap(item)"
          >
            <view class="settings__item-left">
              <text class="settings__item-emoji">{{ item.emoji }}</text>
              <text class="settings__item-label">{{ item.label }}</text>
            </view>
            <view class="settings__item-right">
              <switch
                v-if="item.type === 'switch'"
                :checked="item.value"
                color="#FFB703"
                @change="(e: any) => item.value = e.detail.value"
              />
              <text v-else class="settings__arrow">›</text>
            </view>
          </view>
        </view>
      </view>

      <!-- 账号安全 -->
      <view class="settings__module">
        <view class="settings__module-title"><text>账号与安全</text></view>
        <view class="settings__module-list">
          <view
            v-for="item in accountItems"
            :key="item.label"
            class="settings__item"
            @click="onItemTap(item)"
          >
            <view class="settings__item-left">
              <text class="settings__item-emoji">{{ item.emoji }}</text>
              <text class="settings__item-label">{{ item.label }}</text>
            </view>
            <view class="settings__item-right">
              <text v-if="item.value" class="settings__item-value">{{ item.value }}</text>
              <text class="settings__arrow">›</text>
            </view>
          </view>
        </view>
      </view>

      <!-- 危险区：注销 -->
      <view class="settings__module settings__module--danger">
        <view class="settings__module-list">
          <view class="settings__item" @click="onDeactivate">
            <view class="settings__item-left">
              <text class="settings__item-emoji">⚠️</text>
              <text class="settings__item-label settings__item-label--danger">账号注销</text>
            </view>
            <view class="settings__item-right">
              <text class="settings__arrow">›</text>
            </view>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { reactive } from 'vue'

const settingItems = reactive([
  { emoji: '❓', label: '常见问题/QA',                     type: 'nav'    },
  { emoji: '📖', label: '新手上门路演',                     type: 'nav'    },
  { emoji: '📄', label: '个人成长教练实施规则和商业伦理',  type: 'nav'    },
  { emoji: '📋', label: '服务合规声明',                     type: 'nav'    },
  { emoji: '👥', label: '未成年人模式',                     type: 'switch', value: false },
  { emoji: '📧', label: '客服微信与邮箱',                   type: 'nav'    },
  { emoji: '🔔', label: '侵权投诉入口',                     type: 'nav'    },
])

const accountItems = reactive([
  { emoji: '📱', label: '手机号',   type: 'nav', value: '已绑定' },
  { emoji: '🔐', label: '账号找回', type: 'nav', value: ''       },
  { emoji: '🔒', label: '隐私设置', type: 'nav', value: ''       },
])

function onItemTap(item: any) {
  if (item.type === 'switch') return
  uni.showToast({ title: `${item.label}（开发中）`, icon: 'none' })
}

function onDeactivate() {
  uni.showModal({
    title: '注销账号',
    content: '注销后账号数据将无法恢复，确定继续吗？',
    confirmColor: '#e88888',
    success: ({ confirm }) => {
      if (confirm) {
        uni.showToast({ title: '功能开发中', icon: 'none' })
      }
    },
  })
}
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.settings {
  min-height: 100vh;
  background: $color-bg-warm;
  display: flex;
  flex-direction: column;

  &__header {
    display: flex;
    align-items: center;
    gap: 24rpx;
    padding: 30rpx 30rpx 24rpx;
    background: $color-bg-warm;
  }
  &__back {
    width: 72rpx;
    height: 72rpx;
    border-radius: 50%;
    background: $color-primary-light;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }
  &__back-icon {
    font-size: $font-xl;
    color: $color-primary;
  }
  &__title {
    font-size: $font-2xl;
    font-weight: 700;
    color: $color-text;
  }

  &__scroll {
    flex: 1;
    padding: 0 30rpx 60rpx;
  }

  &__module {
    background: $color-bg-white;
    border-radius: 40rpx;
    box-shadow: $shadow-soft;
    overflow: hidden;
    margin-bottom: 24rpx;
    &--danger { margin-top: 8rpx; }
  }
  &__module-title {
    padding: 32rpx 30rpx;
    font-size: $font-base;
    font-weight: 600;
    color: $color-text-deep;
    border-bottom: 2rpx solid $color-border;
  }
  &__module-list {}

  &__item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 32rpx 30rpx;
    border-bottom: 2rpx solid $color-border;
    &:last-child { border-bottom: none; }
  }
  &__item-left {
    display: flex;
    align-items: center;
    gap: 24rpx;
    flex: 1;
  }
  &__item-emoji { font-size: $font-lg; }
  &__item-label {
    font-size: $font-md;
    color: $color-text-deep;
    flex: 1;
    &--danger { color: #e88888; }
  }
  &__item-right {
    display: flex;
    align-items: center;
    gap: 12rpx;
    color: $color-text-gray;
  }
  &__item-value {
    font-size: $font-sm;
    color: $color-text-gray;
  }
  &__arrow {
    font-size: $font-lg;
    color: #ccc;
    opacity: 0.8;
  }
}
</style>
