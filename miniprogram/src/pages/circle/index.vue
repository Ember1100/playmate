<template>
  <view class="circle">
    <!-- 搜索栏 -->
    <view class="circle__search-bar">
      <text class="circle__search-icon">🔍</text>
      <input class="circle__search-input" placeholder="搜索群聊..." placeholder-style="color:#9e9e9e" />
      <text class="circle__search-star">⭐</text>
    </view>

    <!-- 顶部 Tab -->
    <view class="circle__tab-bar">
      <view
        v-for="tab in tabs"
        :key="tab.key"
        class="circle__tab-item"
        :class="{ active: activeTab === tab.key }"
        @click="activeTab = tab.key"
      >
        <text>{{ tab.label }}</text>
      </view>
    </view>

    <!-- 推荐页 -->
    <scroll-view v-if="activeTab === 'home'" scroll-y class="circle__page"
      refresher-enabled :refresher-triggered="refreshing"
      @refresherrefresh="onRefresh" @scrolltolower="onLoadMore">

      <!-- 发布入口 -->
      <view class="circle__post-box">
        <view class="circle__post-item" @click="uni.showToast({title:'发布话题',icon:'none'})">
          <view class="circle__post-icon"><text>✏️</text></view>
          <text class="circle__post-text">发布话题</text>
        </view>
        <view class="circle__post-item" @click="uni.showToast({title:'发布投票',icon:'none'})">
          <view class="circle__post-icon"><text>📊</text></view>
          <text class="circle__post-text">发布投票</text>
          <text class="circle__post-arrow">›</text>
        </view>
      </view>

      <!-- 观点交锋 -->
      <view class="circle__debate">
        <view class="circle__debate-title">
          <text class="circle__debate-icon">💬</text>
          <text>今日观点交锋</text>
        </view>
        <view class="circle__debate-content">
          <view class="circle__debate-side pro">
            <text class="circle__debate-tag">正方</text>
            <text class="circle__debate-body">努力一定能改变命运，坚持付出就会有回报，脚踏实地才是人生正道</text>
          </view>
          <view class="circle__debate-side con">
            <text class="circle__debate-tag">反方</text>
            <text class="circle__debate-body">选择比努力更重要，方向错了越努力越失败，思维认知决定上限</text>
          </view>
        </view>
      </view>

      <!-- 标签分类 -->
      <scroll-view class="circle__tags" scroll-x>
        <view class="circle__tags-inner">
          <view
            v-for="tag in catTags"
            :key="tag.key"
            class="circle__tag"
            :class="{ active: activeCat === tag.key }"
            @click="activeCat = tag.key"
          >{{ tag.label }}</view>
        </view>
      </scroll-view>

      <!-- 话题卡片列表 -->
      <view v-for="item in topics" :key="item.id" class="circle__topic-card"
        @click="uni.navigateTo({url:'/pages/circle/topic-detail?id='+item.id})">
        <view class="circle__topic-cover">
          <image :src="item.cover" mode="aspectFill" style="width:100%;height:100%" />
        </view>
        <view class="circle__topic-content">
          <view>
            <text class="circle__topic-title">{{ item.title }}</text>
            <text class="circle__topic-desc">{{ item.desc }}</text>
          </view>
          <view class="circle__topic-footer">
            <text class="circle__topic-meta">{{ item.author }} · {{ item.time }}</text>
            <button class="circle__join-btn" @click.stop="">热议</button>
          </view>
        </view>
      </view>

      <view v-if="!hasMore && topics.length" class="circle__end"><text>没有更多了</text></view>
    </scroll-view>

    <!-- 话题页（占位） -->
    <view v-if="activeTab === 'topic'" class="circle__placeholder">
      <text>话题广场（即将上线）</text>
    </view>

    <!-- 群聊页 -->
    <scroll-view v-if="activeTab === 'chat'" scroll-y class="circle__page">
      <view class="circle__chat-layout">
        <!-- 左侧分类 -->
        <view class="circle__chat-cats">
          <view
            v-for="cat in chatCats"
            :key="cat"
            class="circle__chat-cat"
            :class="{ active: activeChatCat === cat }"
            @click="activeChatCat = cat"
          >{{ cat }}</view>
        </view>
        <!-- 右侧群列表 -->
        <view class="circle__chat-groups">
          <view v-for="g in chatGroups" :key="g.id" class="circle__chat-group"
            @click="uni.navigateTo({url:'/pages/circle/group-chat?id='+g.id})">
            <view class="circle__chat-avatar">
              <image :src="g.avatar" mode="aspectFill" style="width:100%;height:100%" />
            </view>
            <view class="circle__chat-info">
              <text class="circle__chat-name">{{ g.name }}</text>
              <text class="circle__chat-desc">{{ g.desc }}</text>
            </view>
            <view class="circle__chat-right">
              <button class="circle__join-group-btn">加入</button>
            </view>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
  <PmTabBar :current="0" />
</template>

<script setup lang="ts">
import { ref } from 'vue'
import PmTabBar from '@/components/PmTabBar.vue'

const tabs = [
  { key: 'home', label: '推荐' },
  { key: 'topic', label: '话题' },
  { key: 'chat', label: '群聊' },
]
const activeTab = ref('home')

const catTags = [
  { key: 'hot',          label: '热点' },
  { key: 'follow',       label: '关注' },
  { key: 'growth',       label: '自我成长' },
  { key: 'cognition',    label: '认知升级' },
  { key: 'emotion',      label: '情绪管理' },
  { key: 'relationship', label: '人际关系' },
  { key: 'career',       label: '职场进阶' },
  { key: 'more',         label: '更多' },
]
const activeCat = ref('hot')

const topics = ref([
  { id: '1', title: '职场内卷是否值得，年轻人该如何选择', desc: '内卷时代，是被迫竞争还是寻找破局之路，理性看待职场内卷', author: '热点观察员', time: '30分钟前', cover: 'https://picsum.photos/seed/work1/200/160' },
  { id: '2', title: '考研考公热背后的真实选择', desc: '分析考研考公的利弊，帮助年轻人做出理性决策', author: '教育博主', time: '1小时前', cover: 'https://picsum.photos/seed/exam1/200/160' },
  { id: '3', title: '35岁职场危机如何破局', desc: '35岁不是终点，而是新的起点，掌握职业转型的关键策略', author: '职业规划师', time: '2小时前', cover: 'https://picsum.photos/seed/career1/200/160' },
  { id: '4', title: '北漂十年，我终于想清楚了', desc: '分享一个普通人的成长经历，关于选择和坚持', author: '生活记录者', time: '3小时前', cover: 'https://picsum.photos/seed/life1/200/160' },
])

const hasMore = ref(true)
const refreshing = ref(false)

async function onRefresh() {
  refreshing.value = true
  setTimeout(() => { refreshing.value = false }, 1000)
}
function onLoadMore() {}

const chatCats = ['全部', '兴趣', '职场', '生活', '学习', '运动']
const activeChatCat = ref('全部')
const chatGroups = [
  { id: '1', name: '周末骑行群', desc: '200+ 成员 · 每周活动', avatar: 'https://picsum.photos/seed/bike/96/96' },
  { id: '2', name: '职场成长交流', desc: '500+ 成员 · 最活跃', avatar: 'https://picsum.photos/seed/work2/96/96' },
  { id: '3', name: '读书打卡社', desc: '150+ 成员 · 每日打卡', avatar: 'https://picsum.photos/seed/book1/96/96' },
]
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.circle {
  min-height: 100vh;
  background: $color-bg;
  display: flex;
  flex-direction: column;

  &__search-bar {
    display: flex;
    align-items: center;
    background: #FFF5E1;
    border-radius: 44rpx;
    padding: 22rpx 32rpx;
    margin: 24rpx 24rpx 0;
    border: 2rpx solid rgba(255,183,3,0.15);
  }
  &__search-icon { color: #999; font-size: $font-lg; }
  &__search-input {
    flex: 1;
    border: none;
    background: transparent;
    font-size: $font-base;
    margin-left: 16rpx;
    color: $color-text-deep;
  }
  &__search-star { font-size: $font-lg; }

  &__tab-bar {
    display: flex;
    justify-content: center;
    gap: 80rpx;
    margin: 36rpx 24rpx 36rpx;
  }
  &__tab-item {
    font-size: $font-lg;
    color: #999;
    padding: 12rpx 0;
    position: relative;
    font-weight: 500;
    &.active {
      color: $color-text;
      font-weight: 600;
      &::after {
        content: '';
        position: absolute;
        bottom: 0; left: 0;
        width: 100%; height: 6rpx;
        background: $color-primary;
        border-radius: 4rpx;
      }
    }
  }

  &__page {
    flex: 1;
    padding: 0 24rpx;
  }
  &__placeholder {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    color: $color-text-gray;
    font-size: $font-base;
  }

  // 发布入口
  &__post-box {
    background: $color-primary;
    border-radius: 28rpx;
    padding: 24rpx 32rpx;
    margin-bottom: 16rpx;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: $shadow-soft;
  }
  &__post-item {
    display: flex;
    align-items: center;
    gap: 16rpx;
    color: #fff;
  }
  &__post-icon {
    width: 64rpx; height: 64rpx;
    background: rgba(255,255,255,0.2);
    border-radius: 16rpx;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: $font-xl;
  }
  &__post-text { font-size: $font-md; font-weight: 600; }
  &__post-arrow { color: #fff; font-size: $font-lg; }

  // 观点交锋
  &__debate {
    background: $color-bg-white;
    border-radius: 28rpx;
    padding: 28rpx;
    margin-bottom: 32rpx;
    box-shadow: $shadow-soft;
    border: 2rpx solid $color-border;
  }
  &__debate-title {
    display: flex;
    align-items: center;
    gap: 12rpx;
    font-size: $font-lg;
    font-weight: 600;
    color: $color-text;
    margin-bottom: 24rpx;
  }
  &__debate-icon { font-size: $font-xl; color: $color-primary; }
  &__debate-content {
    display: flex;
    gap: 24rpx;
  }
  &__debate-side {
    flex: 1;
    padding: 20rpx;
    border-radius: 20rpx;
    font-size: $font-sm;
    line-height: 1.5;
    &.pro { background: #FFF5E1; color: #D36A00; border: 2rpx solid #FFE8C0; }
    &.con { background: #F7F7F7; color: #555; border: 2rpx solid #EEE; }
  }
  &__debate-tag {
    font-size: $font-xs;
    font-weight: 700;
    display: block;
    margin-bottom: 10rpx;
  }
  &__debate-body { font-size: $font-sm; line-height: 1.5; }

  // 标签
  &__tags { white-space: nowrap; margin-bottom: 32rpx; }
  &__tags-inner {
    display: flex;
    gap: 18rpx;
    padding: 0 4rpx 12rpx;
  }
  &__tag {
    background: $color-bg-white;
    border: 2rpx solid $color-border-warm;
    border-radius: 40rpx;
    padding: 12rpx 28rpx;
    font-size: $font-sm;
    color: #666;
    white-space: nowrap;
    box-shadow: 0 2rpx 8rpx rgba(0,0,0,0.03);
    flex-shrink: 0;
    &.active {
      background: $color-primary;
      color: #fff;
      border-color: $color-primary;
      box-shadow: 0 4rpx 12rpx rgba(255,183,3,0.3);
    }
  }

  // 话题卡片
  &__topic-card {
    background: $color-bg-white;
    border-radius: 28rpx;
    padding: 26rpx;
    margin-bottom: 28rpx;
    display: flex;
    align-items: stretch;
    gap: 24rpx;
    box-shadow: 0 6rpx 24rpx rgba(0,0,0,0.05);
    border: 2rpx solid $color-border;
  }
  &__topic-cover {
    width: 180rpx;
    height: 164rpx;
    border-radius: 20rpx;
    overflow: hidden;
    background: #eee;
    flex-shrink: 0;
  }
  &__topic-content {
    flex: 1;
    min-width: 0;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    overflow: hidden;
  }
  &__topic-title {
    font-size: $font-md;
    font-weight: 600;
    color: $color-text;
    margin-bottom: 10rpx;
    line-height: 1.4;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    word-break: break-word;
  }
  &__topic-desc {
    font-size: $font-sm;
    color: #777;
    line-height: 1.5;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    word-break: break-word;
    flex: 1;
  }
  &__topic-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 16rpx;
    flex-shrink: 0;
  }
  &__topic-meta {
    font-size: $font-xs;
    color: #999;
    flex: 1;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    margin-right: 16rpx;
  }
  &__join-btn {
    background: $color-primary;
    color: #fff;
    border: none;
    border-radius: 36rpx;
    padding: 10rpx 26rpx;
    font-size: $font-sm;
    font-weight: 500;
    box-shadow: 0 4rpx 12rpx rgba(255,183,3,0.25);
    flex-shrink: 0;
    line-height: 1.5;
    &::after { border: none; }
  }

  &__end {
    text-align: center;
    padding: 40rpx;
    font-size: $font-sm;
    color: $color-text-hint;
  }

  // 群聊
  &__chat-layout {
    display: flex;
    padding: 16rpx 0;
  }
  &__chat-cats {
    width: 160rpx;
    flex-shrink: 0;
    padding-right: 16rpx;
  }
  &__chat-cat {
    font-size: $font-sm;
    color: #666;
    margin-bottom: 24rpx;
    padding: 8rpx 16rpx;
    border-radius: 16rpx;
    &.active { background: $color-primary; color: #fff; font-weight: 600; }
  }
  &__chat-groups { flex: 1; }
  &__chat-group {
    display: flex;
    align-items: center;
    gap: 20rpx;
    padding: 20rpx 0;
    border-bottom: 2rpx solid $color-border-warm;
  }
  &__chat-avatar {
    width: 96rpx; height: 96rpx;
    border-radius: 16rpx;
    overflow: hidden;
    background: $color-primary-light;
    flex-shrink: 0;
  }
  &__chat-info { flex: 1; }
  &__chat-name {
    font-size: $font-base;
    font-weight: 600;
    color: $color-text;
    display: block;
    margin-bottom: 6rpx;
  }
  &__chat-desc { font-size: $font-xs; color: #999; }
  &__chat-right {}
  &__join-group-btn {
    background: $color-primary;
    color: #fff;
    border: none;
    border-radius: 24rpx;
    padding: 8rpx 20rpx;
    font-size: $font-xs;
    font-weight: 500;
    &::after { border: none; }
  }
}
</style>
