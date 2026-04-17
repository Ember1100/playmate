<template>
  <view class="chat">
    <!-- 成员人数提示 -->
    <view class="chat__member-bar">
      <text class="chat__member-text">{{ groupName }} · {{ memberCount }}人</text>
    </view>

    <!-- 消息列表 -->
    <scroll-view
      scroll-y
      class="chat__messages"
      :scroll-top="scrollTop"
      :scroll-with-animation="true"
    >
      <view class="chat__messages-inner">
        <template v-for="(item, index) in groupedMessages" :key="item.id">
          <!-- 时间戳 -->
          <view v-if="item.showTime" class="chat__timestamp">
            <text>{{ formatTimestamp(item.created_at) }}</text>
          </view>

          <!-- 系统消息（type=99） -->
          <view v-if="item.type === 99" class="chat__sys-msg">
            <text>{{ item.content }}</text>
          </view>

          <!-- 普通消息气泡 -->
          <view v-else class="chat__msg-row" :class="{ 'chat__msg-row--me': item.isMe }">
            <!-- 对方头像 -->
            <view v-if="!item.isMe" class="chat__avatar" :style="{ backgroundColor: avatarColor(item.sender_id) }">
              <text class="chat__avatar-text">{{ item.sender_username.charAt(0) }}</text>
            </view>

            <view class="chat__bubble-wrap">
              <!-- 发送者名字（仅对方显示） -->
              <text v-if="!item.isMe" class="chat__sender-name">{{ item.sender_username }}</text>

              <!-- 撤回 -->
              <text v-if="item.is_recalled" class="chat__recalled">
                {{ item.isMe ? '你撤回了一条消息' : `${item.sender_username}撤回了一条消息` }}
              </text>
              <!-- 图片 -->
              <image
                v-else-if="item.type === 2 && item.media_url"
                :src="item.media_url"
                class="chat__img"
                mode="widthFix"
                @click="previewImage(item.media_url)"
              />
              <!-- 文字 -->
              <view
                v-else
                class="chat__bubble"
                :class="item.isMe ? 'chat__bubble--me' : 'chat__bubble--other'"
              >
                <text class="chat__bubble-text" :class="{ 'chat__bubble-text--me': item.isMe }">
                  {{ item.content }}
                </text>
              </view>
            </view>

            <!-- 自己头像 -->
            <view v-if="item.isMe" class="chat__avatar chat__avatar--me">
              <text class="chat__avatar-text">我</text>
            </view>
          </view>
        </template>

        <view style="height: 16rpx;" />
      </view>
    </scroll-view>

    <!-- 输入栏 -->
    <view class="chat__input-bar">
      <view class="chat__input-wrap">
        <input
          v-model="inputText"
          class="chat__input"
          placeholder="发消息..."
          placeholder-style="color:#BCBAB5"
          confirm-type="send"
          @confirm="sendText"
          :adjust-position="true"
        />
      </view>
      <view
        class="chat__send-btn"
        :class="{ active: inputText.trim().length > 0 }"
        @click="sendText"
      >
        <text class="chat__send-icon">➤</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
import { getGroupMessages, type GroupMessage } from '@/api/im'

// ── URL 参数 ──────────────────────────────────────────────────────────────────

const pages       = getCurrentPages()
const currentPage = pages[pages.length - 1] as any
const groupId     = currentPage?.options?.groupId as string ?? ''
const groupName   = decodeURIComponent(currentPage?.options?.name ?? '群聊')
const myId        = uni.getStorageSync('user_id') || 'me'

// ── 状态 ──────────────────────────────────────────────────────────────────────

const messages    = ref<(GroupMessage & { isMe: boolean })[]>([])
const inputText   = ref('')
const scrollTop   = ref(0)
const memberCount = ref(0)

// ── 头像颜色池 ────────────────────────────────────────────────────────────────

const COLOR_POOL = ['#7F77DD', '#4ECDC4', '#FF6B6B', '#FFBE0B', '#06D6A0', '#5DCAA5', '#FF9F43', '#A29BFE']
const colorMap = new Map<string, string>()

function avatarColor(senderId: string): string {
  if (!colorMap.has(senderId)) {
    colorMap.set(senderId, COLOR_POOL[colorMap.size % COLOR_POOL.length])
  }
  return colorMap.get(senderId)!
}

// ── Mock 数据 ─────────────────────────────────────────────────────────────────

interface MockLine {
  sender_id: string
  sender_username: string
  content: string
  offsetMin: number
  type?: number   // 99 = 系统消息
}

const MOCK_SCRIPTS: Record<string, { memberCount: number; lines: MockLine[] }> = {
  'mock-group-1': {
    memberCount: 8,
    lines: [
      { sender_id: 'sys',      sender_username: '',     content: '小赵 加入了群聊',              offsetMin: 4320, type: 99 },
      { sender_id: 'zhao',     sender_username: '小赵', content: '大家好，我是新来的！',           offsetMin: 4310 },
      { sender_id: 'ali',      sender_username: '阿李', content: '欢迎欢迎！我们每天早上六点出发', offsetMin: 4300 },
      { sender_id: 'zhao',     sender_username: '小赵', content: '好的，我会准时到的',             offsetMin: 4290 },
      { sender_id: 'xiaomei',  sender_username: '小美', content: '明天天气不错，适合跑步 🌤️',     offsetMin: 120  },
      { sender_id: 'ali',      sender_username: '阿李', content: '对，风也不大',                  offsetMin: 115  },
      { sender_id: 'xiaomei',  sender_username: '小美', content: '有没有人带补给？上次忘带水了',  offsetMin: 110  },
      { sender_id: myId,       sender_username: '我',   content: '我带两瓶，够用',                offsetMin: 105  },
      { sender_id: 'zhao',     sender_username: '小赵', content: '我也带了能量棒，可以分享',       offsetMin: 100  },
      { sender_id: 'ali',      sender_username: '阿李', content: '太棒了！明早六点操场见！',       offsetMin: 15   },
      { sender_id: 'xiaomei',  sender_username: '小美', content: '👍👍👍',                        offsetMin: 10   },
      { sender_id: 'zhao',     sender_username: '小赵', content: '明早六点操场见！',              offsetMin: 5    },
    ],
  },
  'mock-group-2': {
    memberCount: 12,
    lines: [
      { sender_id: 'chen',   sender_username: '陈队长', content: '大家这周末爬天柱山，有没有兴趣？',    offsetMin: 2880 },
      { sender_id: 'wang',   sender_username: '老王',   content: '天柱山多高？',                        offsetMin: 2870 },
      { sender_id: 'chen',   sender_username: '陈队长', content: '主峰1489米，难度中等，适合大众',       offsetMin: 2860 },
      { sender_id: myId,     sender_username: '我',     content: '我报名！需要带什么装备？',             offsetMin: 2850 },
      { sender_id: 'chen',   sender_username: '陈队长', content: '登山鞋、冲锋衣、够喝的水就行',         offsetMin: 2840 },
      { sender_id: 'linlin', sender_username: '琳琳',   content: '我第一次爬，会不会很累？',             offsetMin: 2830 },
      { sender_id: 'wang',   sender_username: '老王',   content: '问题不大，我上次带新手来过，很顺利',   offsetMin: 2820 },
      { sender_id: 'linlin', sender_username: '琳琳',   content: '那好，我也报名！🙋',                   offsetMin: 2810 },
      { sender_id: 'chen',   sender_username: '陈队长', content: '路线已发群里，记得带水',              offsetMin: 240  },
      { sender_id: 'wang',   sender_username: '老王',   content: '收到，我转发给其他人',                 offsetMin: 230  },
      { sender_id: myId,     sender_username: '我',     content: '好的，我看到了，周六见！',             offsetMin: 225  },
      { sender_id: 'linlin', sender_username: '琳琳',   content: '期待！第一次爬山有点小激动 😆',         offsetMin: 60   },
      { sender_id: 'chen',   sender_username: '陈队长', content: '早点睡，养精蓄锐',                    offsetMin: 55   },
      { sender_id: 'wang',   sender_username: '老王',   content: '路线已发群里，记得带水',              offsetMin: 4    },
    ],
  },
}

function buildMock(gId: string): (GroupMessage & { isMe: boolean })[] {
  const script = MOCK_SCRIPTS[gId]
  if (script) memberCount.value = script.memberCount

  const lines = script?.lines ?? [
    { sender_id: 'user-a', sender_username: '群成员A', content: '大家好！',       offsetMin: 60 },
    { sender_id: myId,     sender_username: '我',       content: '大家好～',        offsetMin: 55 },
    { sender_id: 'user-b', sender_username: '群成员B', content: '欢迎！有活动记得叫上我', offsetMin: 30 },
  ]
  const now = Date.now()
  return lines.map((l, i) => ({
    id: `mock-gmsg-${gId}-${i}`,
    group_id: gId,
    sender_id: l.sender_id,
    sender_username: l.sender_username,
    sender_avatar_url: null,
    type: l.type ?? 1,
    content: l.content,
    media_url: null,
    is_recalled: false,
    created_at: new Date(now - l.offsetMin * 60000).toISOString(),
    isMe: l.sender_id === myId,
  }))
}

// ── 计算：带时间戳分组 ────────────────────────────────────────────────────────

interface DisplayMessage extends GroupMessage {
  isMe: boolean
  showTime: boolean
}

const groupedMessages = computed<DisplayMessage[]>(() =>
  messages.value.map((msg, i) => {
    const prev     = messages.value[i - 1]
    const currTime = new Date(msg.created_at).getTime()
    const prevTime = prev ? new Date(prev.created_at).getTime() : 0
    return { ...msg, showTime: !prev || currTime - prevTime > 5 * 60 * 1000 }
  })
)

// ── 工具函数 ──────────────────────────────────────────────────────────────────

function formatTimestamp(iso: string): string {
  const d    = new Date(iso)
  const now  = new Date()
  const diff = now.getTime() - d.getTime()
  const hhmm = `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
  if (diff < 86400000)      return hhmm
  if (diff < 86400000 * 2)  return `昨天 ${hhmm}`
  if (diff < 86400000 * 7)  return `${'日一二三四五六'[d.getDay()]}曜 ${hhmm}`
  return `${d.getMonth()+1}月${d.getDate()}日 ${hhmm}`
}

function previewImage(url: string | null) {
  if (url) uni.previewImage({ urls: [url], current: url })
}

// ── 发消息 ────────────────────────────────────────────────────────────────────

function sendText() {
  const text = inputText.value.trim()
  if (!text) return
  inputText.value = ''
  messages.value.push({
    id: `local-${Date.now()}`,
    group_id: groupId,
    sender_id: myId,
    sender_username: '我',
    sender_avatar_url: null,
    type: 1,
    content: text,
    media_url: null,
    is_recalled: false,
    created_at: new Date().toISOString(),
    isMe: true,
  })
  nextTick(() => { scrollTop.value += 999999 })
  // TODO: sendGroupMessage(groupId, text)
}

// ── 初始化 ────────────────────────────────────────────────────────────────────

onMounted(async () => {
  uni.setNavigationBarTitle({ title: groupName })

  try {
    const resp = await getGroupMessages(groupId)
    const list = (resp.items ?? []).map(m => ({ ...m, isMe: m.sender_id === myId }))
    messages.value = list.length > 0 ? list : buildMock(groupId)
  } catch {
    messages.value = buildMock(groupId)
  }

  nextTick(() => { scrollTop.value += 999999 })
})
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.chat {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: $color-bg-gray;

  // ── 成员栏 ──────────────────────────────────────────────
  &__member-bar {
    background-color: $color-bg-white;
    padding: 12rpx 32rpx;
    border-bottom: 1rpx solid $color-border;
  }

  &__member-text {
    font-size: $font-xs;
    color: $color-text-gray;
  }

  // ── 消息区 ──────────────────────────────────────────────
  &__messages {
    flex: 1;
    padding-bottom: 110rpx;
  }

  &__messages-inner {
    padding: 24rpx 24rpx 0;
  }

  // ── 时间戳 ──────────────────────────────────────────────
  &__timestamp {
    text-align: center;
    margin: 24rpx 0 16rpx;

    text {
      font-size: $font-xs;
      color: $color-text-gray;
      background-color: rgba(0,0,0,0.06);
      padding: 4rpx 20rpx;
      border-radius: 20rpx;
    }
  }

  // ── 系统消息 ─────────────────────────────────────────────
  &__sys-msg {
    text-align: center;
    margin: 16rpx 0;

    text {
      font-size: $font-xs;
      color: $color-text-gray;
      background-color: rgba(0,0,0,0.05);
      padding: 4rpx 24rpx;
      border-radius: 20rpx;
    }
  }

  // ── 消息行 ──────────────────────────────────────────────
  &__msg-row {
    display: flex;
    align-items: flex-start;
    margin-bottom: 24rpx;
    gap: 16rpx;

    &--me {
      flex-direction: row-reverse;
    }
  }

  // ── 头像 ────────────────────────────────────────────────
  &__avatar {
    width: 72rpx;
    height: 72rpx;
    border-radius: $radius-avatar;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;

    &--me {
      background-color: $color-primary;
    }
  }

  &__avatar-text {
    font-size: $font-sm;
    font-weight: 700;
    color: #FFFFFF;
  }

  // ── 气泡区 ──────────────────────────────────────────────
  &__bubble-wrap {
    max-width: 62vw;
    display: flex;
    flex-direction: column;
  }

  &__sender-name {
    font-size: $font-xs;
    color: $color-text-gray;
    margin-bottom: 8rpx;
    padding-left: 4rpx;
  }

  &__bubble {
    padding: 20rpx 28rpx;
    border-radius: 32rpx;
    display: inline-block;
    align-self: flex-start;

    &--other {
      background-color: #FFFFFF;
      border-top-left-radius: 8rpx;
    }

    &--me {
      background-color: $color-primary;
      border-top-right-radius: 8rpx;
      align-self: flex-end;
    }
  }

  &__bubble-text {
    font-size: $font-base;
    color: $color-text;
    line-height: 1.5;

    &--me { color: #FFFFFF; }
  }

  &__recalled {
    font-size: $font-sm;
    color: $color-text-gray;
    font-style: italic;
    padding: 12rpx 0;
  }

  &__img {
    width: 320rpx;
    border-radius: 16rpx;
    display: block;
  }

  // ── 输入栏 ──────────────────────────────────────────────
  &__input-bar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    display: flex;
    align-items: center;
    gap: 16rpx;
    padding: 16rpx 24rpx;
    padding-bottom: calc(16rpx + env(safe-area-inset-bottom));
    background-color: #FFFFFF;
    border-top: 1rpx solid $color-border;
    box-shadow: 0 -2rpx 12rpx rgba(0,0,0,0.04);
  }

  &__input-wrap {
    flex: 1;
    background-color: $color-bg-gray;
    border-radius: 44rpx;
    padding: 0 28rpx;
    height: 72rpx;
    display: flex;
    align-items: center;
  }

  &__input {
    flex: 1;
    font-size: $font-base;
    color: $color-text;
    height: 72rpx;
    line-height: 72rpx;
  }

  &__send-btn {
    width: 72rpx;
    height: 72rpx;
    border-radius: $radius-avatar;
    background-color: $color-border;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;

    &.active { background-color: $color-primary; }
  }

  &__send-icon {
    font-size: 32rpx;
    color: #FFFFFF;
  }
}
</style>
