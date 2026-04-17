<template>
  <view class="im">
    <!-- 顶部标题栏 -->
    <view class="im__header">
      <text class="im__title">消息</text>
      <text class="im__edit" @click="toggleEdit">{{ editMode ? '完成' : '编辑' }}</text>
    </view>

    <!-- 消息类型 Tab -->
    <view class="im__tabs">
      <view
        v-for="tab in tabs"
        :key="tab.key"
        class="im__tab"
        :class="{ active: activeTab === tab.key }"
        @click="activeTab = tab.key"
      >
        <text>{{ tab.label }}</text>
        <view v-if="tab.badgeCount > 0" class="im__tab-dot" />
      </view>
    </view>

    <!-- ── 全部 Tab ─────────────────────────────────────── -->
    <scroll-view
      v-if="activeTab === 'all'"
      scroll-y class="im__scroll"
      refresher-enabled :refresher-triggered="refreshing"
      @refresherrefresh="onRefresh"
    >
      <!-- 快捷通知入口（编辑模式隐藏）-->
      <view v-if="!editMode" class="im__quick">
        <view class="im__quick-item" @click="activeTab = 'system'">
          <view class="im__quick-icon im__quick-icon--system">
            <text class="im__quick-emoji">🔔</text>
          </view>
          <text class="im__quick-label">系统通知</text>
          <view v-if="systemUnread > 0" class="im__quick-badge">{{ systemUnread }}</view>
        </view>
        <view class="im__quick-item" @click="activeTab = 'buddy'">
          <view class="im__quick-icon im__quick-icon--buddy">
            <text class="im__quick-emoji">🤝</text>
          </view>
          <text class="im__quick-label">搭子邀约</text>
          <view v-if="buddyUnread > 0" class="im__quick-badge">{{ buddyUnread }}</view>
        </view>
        <view class="im__quick-item" @click="activeTab = 'interact'">
          <view class="im__quick-icon im__quick-icon--interact">
            <text class="im__quick-emoji">❤️</text>
          </view>
          <text class="im__quick-label">互动消息</text>
          <view v-if="interactUnread > 0" class="im__quick-badge">{{ interactUnread }}</view>
        </view>
      </view>

      <!-- 私信 + 群聊合并列表（编辑模式隐藏标签）-->
      <view v-if="!editMode" class="im__section-label">
        <text>私信 &amp; 群聊</text>
      </view>

      <view v-if="mergedSessions.length === 0" class="im__empty">
        <text class="im__empty-icon">💬</text>
        <text class="im__empty-text">暂无消息，去找个搭伴聊聊吧</text>
      </view>

      <view
        v-for="(item, index) in mergedSessions"
        :key="item.id"
        class="im__conv-item"
        :class="{ selected: editMode && selectedIds.has(item.id) }"
        @click="editMode ? toggleSelect(item.id) : goSession(item)"
      >
        <!-- 编辑模式复选框 -->
        <view v-if="editMode" class="im__checkbox" :class="{ checked: selectedIds.has(item.id) }">
          <text v-if="selectedIds.has(item.id)" class="im__checkbox-check">✓</text>
        </view>

        <view
          class="im__conv-avatar"
          :style="{ backgroundColor: item.avatarUrl ? 'transparent' : avatarColors[index % avatarColors.length] }"
        >
          <image v-if="item.avatarUrl" :src="item.avatarUrl" class="im__conv-avatar-img" mode="aspectFill" />
          <text v-else class="im__conv-avatar-text">{{ item.name.charAt(0) }}</text>
          <!-- 群聊小标记 -->
          <view v-if="item.sessionType === 'group'" class="im__group-tag">
            <text>群</text>
          </view>
        </view>
        <view class="im__conv-content">
          <view class="im__conv-row">
            <text class="im__conv-name">{{ item.name }}</text>
            <text class="im__conv-time">{{ formatTime(item.lastMessageAt) }}</text>
          </view>
          <view class="im__conv-row">
            <text class="im__conv-msg">{{ item.lastMessage || '暂无消息' }}</text>
            <view v-if="!editMode && item.unreadCount > 0" class="im__unread">
              {{ item.unreadCount > 99 ? '99+' : item.unreadCount }}
            </view>
          </view>
        </view>
      </view>
    </scroll-view>

    <!-- ── 系统通知 Tab ─────────────────────────────────── -->
    <scroll-view
      v-if="activeTab === 'system'"
      scroll-y class="im__scroll"
      refresher-enabled :refresher-triggered="refreshing"
      @refresherrefresh="onRefresh"
    >
      <view v-if="systemNotifs.length === 0" class="im__empty">
        <text class="im__empty-icon">🔔</text>
        <text class="im__empty-text">暂无系统通知</text>
      </view>
      <view
        v-for="n in systemNotifs"
        :key="n.id"
        class="im__notif-item"
        :class="{ unread: !n.is_read }"
        @click="onNotifClick(n)"
      >
        <view class="im__notif-icon im__notif-icon--system">
          <text>📢</text>
        </view>
        <view class="im__notif-body">
          <view class="im__notif-row">
            <text class="im__notif-title">{{ n.title }}</text>
            <text class="im__notif-time">{{ formatTime(n.created_at) }}</text>
          </view>
          <text class="im__notif-content">{{ n.content }}</text>
        </view>
        <view v-if="!n.is_read" class="im__unread-dot" />
      </view>
    </scroll-view>

    <!-- ── 搭子邀约 Tab ─────────────────────────────────── -->
    <scroll-view
      v-if="activeTab === 'buddy'"
      scroll-y class="im__scroll"
      refresher-enabled :refresher-triggered="refreshing"
      @refresherrefresh="onRefresh"
    >
      <view v-if="buddyNotifs.length === 0" class="im__empty">
        <text class="im__empty-icon">🤝</text>
        <text class="im__empty-text">暂无搭子邀约</text>
      </view>
      <view
        v-for="n in buddyNotifs"
        :key="n.id"
        class="im__notif-item"
        :class="{ unread: !n.is_read }"
        @click="onNotifClick(n)"
      >
        <view class="im__notif-icon im__notif-icon--buddy">
          <text>{{ n.type === 'buddy_request' ? '👋' : '🎯' }}</text>
        </view>
        <view class="im__notif-body">
          <view class="im__notif-row">
            <text class="im__notif-title">{{ n.title }}</text>
            <text class="im__notif-time">{{ formatTime(n.created_at) }}</text>
          </view>
          <text class="im__notif-content">{{ n.content }}</text>
          <!-- 接受/拒绝操作按钮（未读邀约才显示）-->
          <view v-if="n.type === 'buddy_request' && !n.is_read" class="im__notif-actions">
            <text class="im__action-btn im__action-btn--reject" @click.stop="respondBuddy(n, false)">拒绝</text>
            <text class="im__action-btn im__action-btn--accept" @click.stop="respondBuddy(n, true)">接受</text>
          </view>
        </view>
        <view v-if="!n.is_read" class="im__unread-dot" />
      </view>
    </scroll-view>

    <!-- ── 编辑模式底部操作栏 ──────────────────────────── -->
    <view v-if="editMode" class="im__edit-bar">
      <view
        class="im__edit-action"
        :class="{ disabled: selectedIds.size === 0 }"
        @click="markReadSelected"
      >
        <text>标记已读</text>
      </view>
      <view
        class="im__edit-action im__edit-action--danger"
        :class="{ disabled: selectedIds.size === 0 }"
        @click="deleteSelected"
      >
        <text>删除</text>
      </view>
    </view>

    <!-- ── 互动消息 Tab ─────────────────────────────────── -->
    <scroll-view
      v-if="activeTab === 'interact'"
      scroll-y class="im__scroll"
      refresher-enabled :refresher-triggered="refreshing"
      @refresherrefresh="onRefresh"
    >
      <view v-if="interactNotifs.length === 0" class="im__empty">
        <text class="im__empty-icon">❤️</text>
        <text class="im__empty-text">暂无互动消息</text>
      </view>
      <view
        v-for="n in interactNotifs"
        :key="n.id"
        class="im__notif-item"
        :class="{ unread: !n.is_read }"
        @click="onNotifClick(n)"
      >
        <view class="im__notif-icon im__notif-icon--interact">
          <text>{{ interactEmoji(n.content) }}</text>
        </view>
        <view class="im__notif-body">
          <view class="im__notif-row">
            <text class="im__notif-title">{{ n.title }}</text>
            <text class="im__notif-time">{{ formatTime(n.created_at) }}</text>
          </view>
          <text class="im__notif-content">{{ n.content }}</text>
        </view>
        <view v-if="!n.is_read" class="im__unread-dot" />
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import {
  getConversations, getGroupSessions, getNotifications,
  markNotificationRead,
  type Conversation, type GroupSession, type Notification,
} from '@/api/im'

// ── 状态 ──────────────────────────────────────────────────────────────────────

const activeTab  = ref('all')
const refreshing = ref(false)
const editMode   = ref(false)
const selectedIds = ref(new Set<string>())

const conversations  = ref<Conversation[]>([])
const groupSessions  = ref<GroupSession[]>([])
const notifications  = ref<Notification[]>([])

const avatarColors = ['#7F77DD', '#4ECDC4', '#FF6B6B', '#FFBE0B', '#06D6A0', '#5DCAA5']

// ── Mock 数据 ─────────────────────────────────────────────────────────────────

const MOCK_CONVERSATIONS: Conversation[] = [
  {
    id: 'mock-conv-1',
    user_a_id: 'me',
    user_b_id: 'user-chen',
    other_user: { id: 'user-chen', username: '陈思远', avatar_url: null },
    last_message: '明天有空一起打球吗？',
    last_message_at: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
    unread_count: 2,
    created_at: new Date(Date.now() - 86400000).toISOString(),
  },
  {
    id: 'mock-conv-2',
    user_a_id: 'me',
    user_b_id: 'user-li',
    other_user: { id: 'user-li', username: '李雨萌', avatar_url: null },
    last_message: '哈哈好的，下午三点见！',
    last_message_at: new Date(Date.now() - 2 * 3600 * 1000).toISOString(),
    unread_count: 0,
    created_at: new Date(Date.now() - 2 * 86400000).toISOString(),
  },
  {
    id: 'mock-conv-3',
    user_a_id: 'me',
    user_b_id: 'user-wang',
    other_user: { id: 'user-wang', username: '王晨阳', avatar_url: null },
    last_message: '[图片]',
    last_message_at: new Date(Date.now() - 86400000).toISOString(),
    unread_count: 0,
    created_at: new Date(Date.now() - 3 * 86400000).toISOString(),
  },
]

const MOCK_GROUP_SESSIONS: GroupSession[] = [
  {
    id: 'mock-group-1',
    name: '🏃 晨跑搭子局',
    avatar_url: null,
    last_message: '小赵：明早六点操场见！',
    last_message_at: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
    unread_count: 3,
    member_count: 8,
  },
  {
    id: 'mock-group-2',
    name: '🏔️ 周末爬山队',
    avatar_url: null,
    last_message: '路线已发群里，记得带水',
    last_message_at: new Date(Date.now() - 4 * 3600 * 1000).toISOString(),
    unread_count: 1,
    member_count: 12,
  },
]

const MOCK_NOTIFICATIONS: Notification[] = [
  {
    id: 'mock-notif-sys-1',
    type: 'system',
    title: '平台公告',
    content: '搭伴新功能「搭子局」正式上线！快去约起来吧 🎉',
    is_read: false,
    created_at: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
  },
  {
    id: 'mock-notif-sys-2',
    type: 'system',
    title: '账号安全提醒',
    content: '你的账号于今日 09:32 在新设备登录，若非本人操作请及时修改密码。',
    is_read: true,
    created_at: new Date(Date.now() - 5 * 3600 * 1000).toISOString(),
  },
  {
    id: 'mock-notif-buddy-1',
    type: 'buddy_request',
    title: '新的搭子申请',
    content: '陈思远 想和你成为搭子，备注：喜欢跑步，一起约？',
    is_read: false,
    created_at: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
    related_id: 'mock-request-1',
  },
  {
    id: 'mock-notif-buddy-2',
    type: 'invitation',
    title: '搭子局邀请',
    content: '李雨萌 邀请你加入「周末爬山队」搭子局',
    is_read: false,
    created_at: new Date(Date.now() - 2 * 3600 * 1000).toISOString(),
    related_id: 'mock-group-2',
  },
  {
    id: 'mock-notif-buddy-3',
    type: 'buddy_request',
    title: '搭子申请已通过',
    content: '恭喜！王晨阳 接受了你的搭子申请，快去打个招呼吧',
    is_read: true,
    created_at: new Date(Date.now() - 86400000).toISOString(),
    related_id: 'mock-request-2',
  },
  {
    id: 'mock-notif-interact-1',
    type: 'interaction',
    title: '点赞了你的话题',
    content: '小赵 赞了你发布的话题「最近发现一条绝美骑行路线」',
    is_read: false,
    created_at: new Date(Date.now() - 45 * 60 * 1000).toISOString(),
    related_id: 'mock-topic-1',
  },
  {
    id: 'mock-notif-interact-2',
    type: 'interaction',
    title: '评论了你的话题',
    content: '李雨萌 评论：「太棒了，下次带我一起！」',
    is_read: true,
    created_at: new Date(Date.now() - 3 * 3600 * 1000).toISOString(),
    related_id: 'mock-topic-1',
  },
]

// ── 计算属性 ──────────────────────────────────────────────────────────────────

interface SessionItem {
  id: string
  sessionType: 'dm' | 'group'
  name: string
  avatarUrl: string | null
  lastMessage: string | null
  lastMessageAt: string | null
  unreadCount: number
}

const mergedSessions = computed<SessionItem[]>(() => {
  const dms: SessionItem[] = conversations.value.map(c => ({
    id: c.id,
    sessionType: 'dm',
    name: c.other_user.username,
    avatarUrl: c.other_user.avatar_url,
    lastMessage: c.last_message,
    lastMessageAt: c.last_message_at,
    unreadCount: c.unread_count,
  }))
  const groups: SessionItem[] = groupSessions.value.map(g => ({
    id: g.id,
    sessionType: 'group',
    name: g.name,
    avatarUrl: g.avatar_url,
    lastMessage: g.last_message,
    lastMessageAt: g.last_message_at,
    unreadCount: g.unread_count,
  }))
  return [...dms, ...groups].sort((a, b) => {
    if (!a.lastMessageAt) return 1
    if (!b.lastMessageAt) return -1
    return new Date(b.lastMessageAt).getTime() - new Date(a.lastMessageAt).getTime()
  })
})

const systemNotifs   = computed(() => notifications.value.filter(n => n.type === 'system'))
const buddyNotifs    = computed(() => notifications.value.filter(n => n.type === 'buddy_request' || n.type === 'invitation'))
const interactNotifs = computed(() => notifications.value.filter(n => n.type === 'interaction'))

const systemUnread   = computed(() => systemNotifs.value.filter(n => !n.is_read).length)
const buddyUnread    = computed(() => buddyNotifs.value.filter(n => !n.is_read).length)
const interactUnread = computed(() => interactNotifs.value.filter(n => !n.is_read).length)

const tabs = computed(() => [
  { key: 'all',      label: '全部',    badgeCount: 0 },
  { key: 'system',   label: '系统通知', badgeCount: systemUnread.value },
  { key: 'buddy',    label: '搭子邀约', badgeCount: buddyUnread.value },
  { key: 'interact', label: '互动消息', badgeCount: interactUnread.value },
])

// ── 工具函数 ──────────────────────────────────────────────────────────────────

function formatTime(iso: string | null | undefined): string {
  if (!iso) return ''
  const d   = new Date(iso)
  const now = new Date()
  const diffMs   = now.getTime() - d.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  if (diffMins < 1)  return '刚刚'
  if (diffMins < 60) return `${diffMins}分钟前`
  const diffHours = Math.floor(diffMins / 60)
  if (diffHours < 24) return `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
  if (diffHours < 24 * 7) {
    const days = ['日','一','二','三','四','五','六']
    return `周${days[d.getDay()]}`
  }
  return `${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`
}

function interactEmoji(content: string): string {
  if (content.includes('赞')) return '👍'
  if (content.includes('评论')) return '💬'
  if (content.includes('收藏')) return '⭐'
  if (content.includes('关注')) return '➕'
  return '❤️'
}

// ── 事件处理 ──────────────────────────────────────────────────────────────────

function goSession(item: SessionItem) {
  if (item.sessionType === 'dm') {
    uni.navigateTo({
      url: `/pages/im/chat?conversationId=${item.id}&username=${encodeURIComponent(item.name)}`,
    })
  } else {
    uni.navigateTo({
      url: `/pages/circle/group-chat?groupId=${item.id}&name=${encodeURIComponent(item.name)}`,
    })
  }
}

async function onNotifClick(n: Notification) {
  if (!n.is_read) {
    n.is_read = true
    markNotificationRead(n.id).catch(() => {})
  }
  if (n.type === 'buddy_request' || n.type === 'invitation') {
    uni.navigateTo({ url: '/pages/buddy/invitations' })
  } else if (n.type === 'interaction' && n.related_id) {
    uni.navigateTo({ url: `/pages/circle/topic-detail?id=${n.related_id}` })
  }
}

async function respondBuddy(n: Notification, accept: boolean) {
  n.is_read = true
  uni.showToast({ title: accept ? '已接受搭子申请' : '已拒绝', icon: 'none' })
  // TODO: 调用 PUT /api/v1/buddy/request/:id/respond
}

function toggleEdit() {
  editMode.value = !editMode.value
  selectedIds.value = new Set()
}

function toggleSelect(id: string) {
  const next = new Set(selectedIds.value)
  if (next.has(id)) next.delete(id)
  else next.add(id)
  selectedIds.value = next
}

function deleteSelected() {
  if (selectedIds.value.size === 0) return
  uni.showModal({
    title: '删除会话',
    content: `确定删除选中的 ${selectedIds.value.size} 个会话？`,
    confirmText: '删除',
    confirmColor: '#E24B4A',
    success: (res) => {
      if (!res.confirm) return
      const ids = selectedIds.value
      conversations.value  = conversations.value.filter(c => !ids.has(c.id))
      groupSessions.value  = groupSessions.value.filter(g => !ids.has(g.id))
      selectedIds.value    = new Set()
      editMode.value       = false
      uni.showToast({ title: '已删除', icon: 'success' })
    },
  })
}

function markReadSelected() {
  if (selectedIds.value.size === 0) return
  const ids = selectedIds.value
  conversations.value = conversations.value.map(c =>
    ids.has(c.id) ? { ...c, unread_count: 0 } : c
  )
  groupSessions.value = groupSessions.value.map(g =>
    ids.has(g.id) ? { ...g, unread_count: 0 } : g
  )
  selectedIds.value = new Set()
  editMode.value    = false
  uni.showToast({ title: '已标记已读', icon: 'success' })
}

// ── 数据加载（API 优先，失败降级 mock）────────────────────────────────────────

async function loadData() {
  const [convResult, groupResult, notifResult] = await Promise.allSettled([
    getConversations(),
    getGroupSessions(),
    getNotifications(),
  ])

  conversations.value = convResult.status === 'fulfilled'
    ? convResult.value
    : MOCK_CONVERSATIONS

  groupSessions.value = groupResult.status === 'fulfilled'
    ? groupResult.value
    : MOCK_GROUP_SESSIONS

  notifications.value = notifResult.status === 'fulfilled'
    ? notifResult.value
    : MOCK_NOTIFICATIONS
}

async function onRefresh() {
  refreshing.value = true
  await loadData()
  refreshing.value = false
}

onMounted(loadData)
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.im {
  min-height: 100vh;
  background-color: $color-bg;
  display: flex;
  flex-direction: column;

  // ── Header ────────────────────────────────────────────
  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 48rpx 32rpx 24rpx;
    background-color: $color-bg-white;
  }

  &__title {
    font-size: $font-2xl;
    font-weight: 700;
    color: $color-text;
  }

  &__edit {
    font-size: $font-base;
    color: $color-primary-dark;
    padding: 8rpx 0;
  }

  // ── Tabs ──────────────────────────────────────────────
  &__tabs {
    display: flex;
    background-color: $color-bg-white;
    padding: 0 16rpx;
    border-bottom: 1rpx solid $color-border;
  }

  &__tab {
    position: relative;
    padding: 20rpx 20rpx;
    font-size: $font-base;
    color: $color-text-gray;

    &.active {
      color: $color-text;
      font-weight: 600;

      &::after {
        content: '';
        position: absolute;
        bottom: 0;
        left: 50%;
        transform: translateX(-50%);
        width: 32rpx;
        height: 4rpx;
        background-color: $color-primary;
        border-radius: 2rpx;
      }
    }
  }

  &__tab-dot {
    position: absolute;
    top: 14rpx;
    right: 10rpx;
    width: 14rpx;
    height: 14rpx;
    background-color: $color-danger;
    border-radius: 50%;
  }

  // ── Scroll container ──────────────────────────────────
  &__scroll {
    flex: 1;
    height: 0;
    min-height: 70vh;
  }

  // ── Quick entry ───────────────────────────────────────
  &__quick {
    display: flex;
    background-color: $color-bg-white;
    margin-bottom: 16rpx;
    padding: 28rpx 0;
    border-bottom: 1rpx solid $color-border;
  }

  &__quick-item {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12rpx;
    position: relative;
  }

  &__quick-icon {
    width: 88rpx;
    height: 88rpx;
    border-radius: $radius-avatar;
    display: flex;
    align-items: center;
    justify-content: center;

    &--system  { background-color: #FFF0E0; }
    &--buddy   { background-color: #E8F4F0; }
    &--interact { background-color: #FFE8E8; }
  }

  &__quick-emoji { font-size: 40rpx; }

  &__quick-label {
    font-size: $font-sm;
    color: $color-text-mid;
  }

  &__quick-badge {
    position: absolute;
    top: 0;
    right: 16%;
    min-width: 32rpx;
    height: 32rpx;
    padding: 0 8rpx;
    background-color: $color-danger;
    border-radius: 16rpx;
    color: #FFFFFF;
    font-size: $font-xs;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  // ── Section label ─────────────────────────────────────
  &__section-label {
    padding: 20rpx 32rpx 12rpx;
    font-size: $font-sm;
    color: $color-text-gray;
  }

  // ── Edit mode bottom bar ──────────────────────────────
  &__edit-bar {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    // account for tab bar (98px) + safe area
    bottom: calc(98px + env(safe-area-inset-bottom));
    display: flex;
    background-color: $color-bg-white;
    border-top: 1rpx solid $color-border;
    z-index: 100;
  }

  &__edit-action {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    height: 96rpx;
    font-size: $font-base;
    color: $color-text;
    font-weight: 500;

    &.disabled {
      opacity: 0.35;
    }

    &--danger { color: $color-danger; }

    & + & {
      border-left: 1rpx solid $color-border;
    }
  }

  // ── Conversation item ─────────────────────────────────
  &__conv-item {
    display: flex;
    align-items: center;
    padding: 24rpx 32rpx;
    background-color: $color-bg-white;
    border-bottom: 1rpx solid $color-border;
    transition: background-color 0.15s;

    &.selected {
      background-color: #FFF3E6;
    }
  }

  // ── Checkbox ──────────────────────────────────────────
  &__checkbox {
    width: 44rpx;
    height: 44rpx;
    border-radius: 50%;
    border: 2rpx solid $color-border;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    margin-right: 20rpx;
    background-color: #FFFFFF;
    transition: all 0.15s;

    &.checked {
      background-color: $color-primary;
      border-color: $color-primary;
    }
  }

  &__checkbox-check {
    font-size: 24rpx;
    color: #FFFFFF;
    font-weight: 700;
    line-height: 1;
  }

  &__conv-avatar {
    width: 88rpx;
    height: 88rpx;
    border-radius: $radius-avatar;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    overflow: visible;
    position: relative;
  }

  &__conv-avatar-img {
    width: 88rpx;
    height: 88rpx;
    border-radius: $radius-avatar;
  }

  &__conv-avatar-text {
    font-size: $font-xl;
    font-weight: 700;
    color: #FFFFFF;
  }

  &__group-tag {
    position: absolute;
    bottom: -4rpx;
    right: -4rpx;
    width: 30rpx;
    height: 30rpx;
    background-color: $color-primary;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;

    text {
      font-size: 18rpx;
      color: #FFFFFF;
      font-weight: 700;
    }
  }

  &__conv-content {
    flex: 1;
    margin-left: 24rpx;
    overflow: hidden;
  }

  &__conv-row {
    display: flex;
    align-items: center;
    justify-content: space-between;

    &:first-child { margin-bottom: 8rpx; }
  }

  &__conv-name {
    font-size: $font-md;
    font-weight: 600;
    color: $color-text;
    flex: 1;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
    margin-right: 16rpx;
  }

  &__conv-time {
    font-size: $font-xs;
    color: $color-text-gray;
    flex-shrink: 0;
  }

  &__conv-msg {
    font-size: $font-sm;
    color: $color-text-gray;
    flex: 1;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
    margin-right: 16rpx;
  }

  &__unread {
    min-width: 36rpx;
    height: 36rpx;
    padding: 0 8rpx;
    background-color: $color-danger;
    border-radius: 18rpx;
    color: #FFFFFF;
    font-size: $font-xs;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  // ── Notification item ─────────────────────────────────
  &__notif-item {
    display: flex;
    align-items: flex-start;
    padding: 24rpx 32rpx;
    background-color: $color-bg-white;
    border-bottom: 1rpx solid $color-border;
    position: relative;

    &.unread {
      background-color: #FFFBF5;
    }
  }

  &__notif-icon {
    width: 72rpx;
    height: 72rpx;
    border-radius: $radius-avatar;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    font-size: 32rpx;

    &--system  { background-color: #FFF0E0; }
    &--buddy   { background-color: #E8F4F0; }
    &--interact { background-color: #FFE8E8; }
  }

  &__notif-body {
    flex: 1;
    margin-left: 20rpx;
    overflow: hidden;
  }

  &__notif-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 8rpx;
  }

  &__notif-title {
    font-size: $font-base;
    font-weight: 600;
    color: $color-text;
    flex: 1;
    margin-right: 12rpx;
  }

  &__notif-time {
    font-size: $font-xs;
    color: $color-text-gray;
    flex-shrink: 0;
  }

  &__notif-content {
    font-size: $font-sm;
    color: $color-text-mid;
    line-height: 1.5;
  }

  &__notif-actions {
    display: flex;
    gap: 16rpx;
    margin-top: 16rpx;
  }

  &__action-btn {
    padding: 10rpx 32rpx;
    border-radius: $radius-button;
    font-size: $font-sm;
    font-weight: 500;

    &--reject {
      background-color: $color-bg-gray;
      color: $color-text-mid;
    }

    &--accept {
      background-color: $color-primary;
      color: #FFFFFF;
    }
  }

  &__unread-dot {
    width: 14rpx;
    height: 14rpx;
    background-color: $color-danger;
    border-radius: 50%;
    flex-shrink: 0;
    margin-top: 8rpx;
    margin-left: 8rpx;
  }

  // ── Empty ─────────────────────────────────────────────
  &__empty {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 120rpx 0;
    gap: 24rpx;
  }

  &__empty-icon { font-size: 80rpx; }

  &__empty-text {
    font-size: $font-base;
    color: $color-text-gray;
  }
}
</style>
