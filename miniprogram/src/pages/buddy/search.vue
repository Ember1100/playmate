<template>
  <view class="search">
    <!-- 顶部搜索栏 -->
    <view class="search__bar">
      <view class="search__bar-input-wrap">
        <text class="search__bar-icon">🔍</text>
        <input
          class="search__bar-input"
          v-model="keyword"
          :focus="autoFocus"
          placeholder="搜索搭子局或搭子..."
          placeholder-style="color:#888780;font-size:28rpx"
          confirm-type="search"
          @confirm="onSearch"
        />
      </view>
      <text class="search__bar-cancel" @click="uni.navigateBack()">取消</text>
    </view>

    <scroll-view scroll-y class="search__scroll">
      <!-- 搜索类型入口 -->
      <view class="search__types">
        <view class="search__type-btn" @click="onSearchType('buddy')">
          <view class="search__type-icon">
            <text>👤</text>
          </view>
          <text class="search__type-label">搜索搭子</text>
        </view>
        <view class="search__type-btn" @click="onSearchType('group')">
          <view class="search__type-icon">
            <text>👥</text>
          </view>
          <text class="search__type-label">搜索搭子局</text>
        </view>
      </view>

      <!-- 大家都在搜 -->
      <view class="search__hot">
        <text class="search__hot-title">大家都在搜</text>
        <view class="search__hot-wrap">
          <view
            v-for="kw in hotSearches"
            :key="kw"
            class="search__hot-tag"
            @click="keyword = kw"
          >
            <text>{{ kw }}</text>
          </view>
        </view>
      </view>

      <!-- 筛选 Tab -->
      <scroll-view scroll-x class="search__filters-scroll">
        <view class="search__filters">
          <view
            v-for="(f, i) in filters"
            :key="f"
            class="search__filter"
            :class="{ active: selectedFilter === i }"
            @click="selectedFilter = i"
          >
            <text>{{ f }}</text>
          </view>
        </view>
      </scroll-view>

      <!-- 搭子网格 -->
      <view class="search__grid">
        <view
          v-for="item in candidates"
          :key="item.name"
          class="search__cell"
          @click="uni.navigateTo({ url: '/pages/buddy/detail?id=' + item.name })"
        >
          <view class="search__cell-avatar" :class="{ female: item.isFemale }">
            <text class="search__cell-avatar-icon">{{ item.isFemale ? '👩' : '👨' }}</text>
          </view>
          <text class="search__cell-name">{{ item.name }}</text>
        </view>
      </view>

      <view style="height: 48rpx" />
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const keyword = ref('')
const autoFocus = ref(true)
const selectedFilter = ref(0)

const filters = ['精选搭子', '新人搭子', '附近搭子', '活跃搭子', '职业搭子']

const hotSearches = [
  '爬山搭子',
  '读书搭子',
  '健身搭子',
  '游戏搭子',
  '电影搭子',
  '旅行搭子',
]

const candidates = [
  { name: '阿毛', isFemale: false },
  { name: '大欢', isFemale: false },
  { name: '小雅', isFemale: true },
  { name: '邓子', isFemale: false },
  { name: '欢哥', isFemale: false },
  { name: '小鱼', isFemale: true },
  { name: '老王', isFemale: false },
  { name: '冬冬', isFemale: true },
]

function onSearch() {
  // TODO: 调用搜索 API
}

function onSearchType(_type: 'buddy' | 'group') {
  // TODO: 切换搜索类型
}
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.search {
  min-height: 100vh;
  background-color: $color-bg;
  display: flex;
  flex-direction: column;

  // ── 搜索栏 ──────────────────────────────────────────────
  &__bar {
    display: flex;
    align-items: center;
    gap: 20rpx;
    padding: 20rpx 24rpx;
    background: #fff;
  }
  &__bar-input-wrap {
    flex: 1;
    display: flex;
    align-items: center;
    height: 84rpx;
    background: #f5f5f5;
    border-radius: 999rpx;
    padding: 0 28rpx;
    gap: 16rpx;
  }
  &__bar-icon {
    font-size: $font-base;
    opacity: 0.55;
  }
  &__bar-input {
    flex: 1;
    font-size: $font-base;
    color: $color-text;
  }
  &__bar-cancel {
    font-size: $font-md;
    color: #FF7A00;
    font-weight: 500;
    flex-shrink: 0;
  }

  &__scroll {
    flex: 1;
    height: 0; // flex 子项滚动需要
  }

  // ── 搜索类型入口 ──────────────────────────────────────────
  &__types {
    display: flex;
    justify-content: space-around;
    padding: 48rpx 48rpx 16rpx;
  }
  &__type-btn {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16rpx;
  }
  &__type-icon {
    width: 128rpx;
    height: 128rpx;
    border-radius: 50%;
    background: #FFF0DC;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 60rpx;
    box-shadow: 0 8rpx 24rpx rgba(255, 122, 0, 0.12);
  }
  &__type-label {
    font-size: $font-base;
    color: $color-text;
    font-weight: 500;
  }

  // ── 大家都在搜 ──────────────────────────────────────────
  &__hot {
    padding: 32rpx 32rpx 0;
  }
  &__hot-title {
    font-size: $font-base;
    font-weight: 700;
    color: #FF7A00;
    display: block;
    margin-bottom: 20rpx;
  }
  &__hot-wrap {
    background: #FFF0DC;
    border-radius: $radius-card;
    padding: 24rpx 28rpx;
    display: flex;
    flex-wrap: wrap;
    gap: 20rpx;
  }
  &__hot-tag {
    padding: 10rpx 24rpx;
    background: #fff;
    border-radius: 999rpx;
    font-size: $font-sm;
    color: $color-text;
  }

  // ── 筛选 Tab ──────────────────────────────────────────
  &__filters-scroll {
    white-space: nowrap;
    padding: 40rpx 0 28rpx;
  }
  &__filters {
    display: flex;
    gap: 20rpx;
    padding: 0 32rpx;
  }
  &__filter {
    flex-shrink: 0;
    padding: 16rpx 32rpx;
    border-radius: 999rpx;
    background: #fff;
    border: 2rpx solid $color-border;
    font-size: $font-sm;
    color: $color-text;

    &.active {
      background: #FF7A00;
      border-color: #FF7A00;
      color: #fff;
      font-weight: 700;
      box-shadow: 0 6rpx 16rpx rgba(255, 122, 0, 0.25);
    }
  }

  // ── 搭子网格 ──────────────────────────────────────────
  &__grid {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 32rpx 16rpx;
    padding: 0 32rpx;
  }
  &__cell {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12rpx;
  }
  &__cell-avatar {
    width: 104rpx;
    height: 104rpx;
    border-radius: 50%;
    background: #f5f5f5;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 3rpx solid $color-border;

    &.female {
      border-color: rgba(255, 122, 0, 0.3);
    }
  }
  &__cell-avatar-icon {
    font-size: 56rpx;
  }
  &__cell-name {
    font-size: $font-sm;
    color: $color-text;
    text-align: center;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    max-width: 100%;
  }
}
</style>
