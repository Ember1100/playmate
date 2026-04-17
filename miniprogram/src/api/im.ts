import { request } from './request'
import type { PageResponse } from './request'

// ── 私信会话 ──────────────────────────────────────────────────────────────────

export interface Conversation {
  id: string
  user_a_id: string
  user_b_id: string
  other_user: { id: string; username: string; avatar_url: string | null }
  last_message: string | null
  last_message_at: string | null
  unread_count: number
  created_at: string
}

export interface Message {
  id: string
  conversation_id: string
  sender_id: string
  /** 1=文字 2=图片 3=语音 */
  type: number
  content: string | null
  media_url: string | null
  is_recalled: boolean
  created_at: string
}

// ── 群聊会话（搭子局 / 社群）────────────────────────────────────────────────

export interface GroupSession {
  id: string
  name: string
  avatar_url: string | null
  last_message: string | null
  last_message_at: string | null
  unread_count: number
  member_count: number
}

export interface GroupMessage {
  id: string
  group_id: string
  sender_id: string
  sender_username: string
  sender_avatar_url: string | null
  /** 1=文字 2=图片 3=语音 */
  type: number
  content: string | null
  media_url: string | null
  is_recalled: boolean
  created_at: string
}

// ── 通知 ──────────────────────────────────────────────────────────────────────

export type NotificationType = 'system' | 'buddy_request' | 'invitation' | 'interaction'

export interface Notification {
  id: string
  type: NotificationType
  title: string
  content: string
  is_read: boolean
  created_at: string
  /** 关联实体 id（搭子请求id / 话题id 等） */
  related_id?: string
}

// ── API 函数 ──────────────────────────────────────────────────────────────────

export function getConversations(): Promise<Conversation[]> {
  return request({ url: '/api/v1/im/conversations' })
}

export function getMessages(conversationId: string, page = 1): Promise<PageResponse<Message>> {
  return request({ url: `/api/v1/im/conversations/${conversationId}/messages?page=${page}` })
}

export function createConversation(user_id: string): Promise<Conversation> {
  return request({ url: '/api/v1/im/conversations', method: 'POST', data: { user_id } })
}

/** 获取已加入的群聊列表（含最新一条消息）— 复用圈子接口，后端按 joined 过滤 */
export function getGroupSessions(): Promise<GroupSession[]> {
  return request({ url: '/api/v1/circle/groups?joined=true&with_last_message=true' })
}

export function getNotifications(): Promise<Notification[]> {
  return request({ url: '/api/v1/notifications' })
}

export function markNotificationRead(id: string): Promise<void> {
  return request({ url: `/api/v1/notifications/${id}/read`, method: 'POST' })
}

export function markAllNotificationsRead(): Promise<void> {
  return request({ url: '/api/v1/notifications/read-all', method: 'POST' })
}

export function getGroupMessages(groupId: string, page = 1): Promise<PageResponse<GroupMessage>> {
  return request({ url: `/api/v1/circle/groups/${groupId}/messages?page=${page}` })
}

export function sendGroupMessage(groupId: string, content: string): Promise<GroupMessage> {
  return request({ url: `/api/v1/circle/groups/${groupId}/messages`, method: 'POST', data: { type: 1, content } })
}

// WebSocket 连接（uni-app 方式）
const WS_URL = 'ws://8.138.190.48:8080/api/v1/im/ws'

let socketTask: UniApp.SocketTask | null = null

export function connectWS(onMessage: (data: any) => void, onClose?: () => void) {
  const token = uni.getStorageSync('access_token')
  socketTask = uni.connectSocket({
    url: `${WS_URL}?token=${token}`,
    complete: () => {},
  })
  uni.onSocketMessage((res) => {
    try {
      onMessage(JSON.parse(res.data as string))
    } catch {}
  })
  uni.onSocketClose(() => {
    socketTask = null
    onClose?.()
  })
}

export function sendWS(data: object) {
  uni.sendSocketMessage({ data: JSON.stringify(data) })
}

export function closeWS() {
  socketTask?.close({})
  socketTask = null
}
