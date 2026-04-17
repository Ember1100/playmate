<template>
  <view class="chat">
    <!-- 消息列表 -->
    <scroll-view
      ref="scrollRef"
      scroll-y
      class="chat__messages"
      :scroll-top="scrollTop"
      :scroll-with-animation="true"
    >
      <view class="chat__messages-inner">
        <!-- 时间戳分组 -->
        <template v-for="(item, index) in groupedMessages" :key="item.id">
          <view
            v-if="item.showTime"
            class="chat__timestamp"
          >
            <text>{{ formatTimestamp(item.createdAt) }}</text>
          </view>

          <!-- 消息气泡 -->
          <view
            class="chat__msg-row"
            :class="{ 'chat__msg-row--me': item.isMe }"
          >
            <!-- 对方头像 -->
            <view v-if="!item.isMe" class="chat__avatar">
              <text class="chat__avatar-text">{{ otherName.charAt(0) }}</text>
            </view>

            <!-- 气泡 -->
            <view class="chat__bubble-wrap">
              <!-- 已撤回 -->
              <text v-if="item.isRecalled" class="chat__recalled">
                {{ item.isMe ? '你撤回了一条消息' : `${otherName}撤回了一条消息` }}
              </text>
              <!-- 图片 -->
              <image
                v-else-if="item.type === 2 && item.mediaUrl"
                :src="item.mediaUrl"
                class="chat__img"
                mode="widthFix"
                @click="previewImage(item.mediaUrl)"
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

        <!-- 底部留白（保证最后一条消息不被输入栏遮住）-->
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
import { getMessages, type Message } from '@/api/im'

// ── URL 参数 ──────────────────────────────────────────────────────────────────

const pages      = getCurrentPages()
const currentPage = pages[pages.length - 1] as any
const conversationId = currentPage?.options?.conversationId as string ?? ''
const otherName      = decodeURIComponent(currentPage?.options?.username ?? '对方')
const myId           = uni.getStorageSync('user_id') || 'me'

// ── 状态 ──────────────────────────────────────────────────────────────────────

const messages   = ref<(Message & { isMe: boolean })[]>([])
const inputText  = ref('')
const scrollTop  = ref(0)

// ── Mock 数据 ─────────────────────────────────────────────────────────────────

const MOCK_SCRIPTS: Record<string, { sender: 'me' | 'other'; content: string; offsetMin: number }[]> = {
  'mock-conv-1': [
    { sender: 'other', content: '嘿，最近在忙什么呢？',              offsetMin: 150 },
    { sender: 'me',    content: '在准备一个项目，有点忙哈哈',         offsetMin: 140 },
    { sender: 'other', content: '加油！对了，周末有没有空打球？',      offsetMin: 120 },
    { sender: 'me',    content: '周六下午应该可以，几点？',            offsetMin: 110 },
    { sender: 'other', content: '下午两点操场见？',                   offsetMin: 100 },
    { sender: 'me',    content: '好的没问题！',                       offsetMin: 95  },
    { sender: 'other', content: '明天有空一起打球吗？',               offsetMin: 5   },
  ],
  'mock-conv-2': [
    { sender: 'other', content: '你好，看到你也对爬山感兴趣！',        offsetMin: 1500 },
    { sender: 'me',    content: '对啊，你经常爬吗？',                  offsetMin: 1490 },
    { sender: 'other', content: '差不多每个月两次，主要在郊区',         offsetMin: 1480 },
    { sender: 'me',    content: '有没有推荐的线路？',                  offsetMin: 1460 },
    { sender: 'other', content: '可以试试天柱山，难度适中风景很好',     offsetMin: 1440 },
    { sender: 'me',    content: '听起来不错，下次一起？',              offsetMin: 180  },
    { sender: 'other', content: '哈哈好的，下午三点见！',              offsetMin: 120  },
  ],
}

function buildMock(convId: string): (Message & { isMe: boolean })[] {
  const script = MOCK_SCRIPTS[convId] ?? [
    { sender: 'other', content: '你好！很高兴认识你 😊',               offsetMin: 60 },
    { sender: 'me',    content: '你好！我也是，期待我们成为搭伴～',     offsetMin: 50 },
    { sender: 'other', content: '有空一起出来玩吗？',                   offsetMin: 30 },
  ]
  const now = Date.now()
  return script.map((s, i) => ({
    id: `mock-msg-${convId}-${i}`,
    conversation_id: convId,
    sender_id: s.sender === 'me' ? myId : `other-${convId}`,
    type: 1,
    content: s.content,
    media_url: null,
    is_recalled: false,
    created_at: new Date(now - s.offsetMin * 60000).toISOString(),
    isMe: s.sender === 'me',
  }))
}

// ── 计算：带时间戳分组 ────────────────────────────────────────────────────────

interface DisplayMessage extends Message {
  isMe: boolean
  showTime: boolean
}

const groupedMessages = computed<DisplayMessage[]>(() => {
  return messages.value.map((msg, i) => {
    const prev = messages.value[i - 1]
    const currTime = new Date(msg.created_at).getTime()
    const prevTime = prev ? new Date(prev.created_at).getTime() : 0
    const showTime = !prev || (currTime - prevTime) > 5 * 60 * 1000
    return { ...msg, showTime }
  })
})

// ── 工具函数 ──────────────────────────────────────────────────────────────────

function formatTimestamp(iso: string): string {
  const d   = new Date(iso)
  const now = new Date()
  const diffMs   = now.getTime() - d.getTime()
  const diffDays = Math.floor(diffMs / 86400000)
  const hhmm = `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
  if (diffDays === 0) return hhmm
  if (diffDays === 1) return `昨天 ${hhmm}`
  if (diffDays < 7)  {
    const days = ['日','一','二','三','四','五','六']
    return `周${days[d.getDay()]} ${hhmm}`
  }
  return `${d.getMonth()+1}月${d.getDate()}日 ${hhmm}`
}

function previewImage(url: string) {
  uni.previewImage({ urls: [url], current: url })
}

// ── 发消息 ────────────────────────────────────────────────────────────────────

function sendText() {
  const text = inputText.value.trim()
  if (!text) return
  inputText.value = ''

  const newMsg: Message & { isMe: boolean } = {
    id: `local-${Date.now()}`,
    conversation_id: conversationId,
    sender_id: myId,
    type: 1,
    content: text,
    media_url: null,
    is_recalled: false,
    created_at: new Date().toISOString(),
    isMe: true,
  }
  messages.value.push(newMsg)
  scrollToBottom()

  // TODO: 通过 WebSocket 发送给后端
}

function scrollToBottom() {
  nextTick(() => {
    // 给一个足够大的 scrollTop 触发滚动到底部
    scrollTop.value = scrollTop.value + 999999
  })
}

// ── 初始化 ────────────────────────────────────────────────────────────────────

onMounted(async () => {
  // 设置导航栏标题
  uni.setNavigationBarTitle({ title: otherName })

  try {
    const resp = await getMessages(conversationId)
    const list = (resp.items ?? []).map(m => ({
      ...m,
      isMe: m.sender_id === myId,
    }))
    messages.value = list.length > 0 ? list : buildMock(conversationId)
  } catch {
    messages.value = buildMock(conversationId)
  }

  scrollToBottom()
})
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.chat {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: $color-bg-gray;

  // ── 消息列表 ────────────────────────────────────────────
  &__messages {
    flex: 1;
    // 底部留出输入栏高度
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

  // ── 消息行 ──────────────────────────────────────────────
  &__msg-row {
    display: flex;
    align-items: flex-end;
    margin-bottom: 20rpx;
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
    background-color: $color-primary-light;
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
    color: $color-text;
  }

  &__avatar--me &__avatar-text {
    color: #FFFFFF;
  }

  // ── 气泡 ────────────────────────────────────────────────
  &__bubble-wrap {
    max-width: 65vw;
  }

  &__bubble {
    padding: 20rpx 28rpx;
    border-radius: 32rpx;
    display: inline-block;

    &--other {
      background-color: #FFFFFF;
      border-bottom-left-radius: 8rpx;
    }

    &--me {
      background-color: $color-primary;
      border-bottom-right-radius: 8rpx;
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
    transition: background-color 0.2s;
    flex-shrink: 0;

    &.active {
      background-color: $color-primary;
    }
  }

  &__send-icon {
    font-size: 32rpx;
    color: #FFFFFF;
  }
}
</style>
