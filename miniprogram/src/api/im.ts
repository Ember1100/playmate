import { request } from './request'
import type { PageResponse } from './request'

export interface Conversation {
  id: string
  user_a_id: string
  user_b_id: string
  other_user: { id: string; username: string; avatar_url: string | null }
  last_message: string | null
  unread_count: number
  created_at: string
}

export interface Message {
  id: string
  conversation_id: string
  sender_id: string
  type: number          // 1文字 2图片 3语音
  content: string | null
  media_url: string | null
  is_recalled: boolean
  created_at: string
}

export function getConversations(): Promise<Conversation[]> {
  return request({ url: '/api/v1/im/conversations' })
}

export function getMessages(conversationId: string, page = 1): Promise<PageResponse<Message>> {
  return request({ url: `/api/v1/im/conversations/${conversationId}/messages?page=${page}` })
}

export function createConversation(user_id: string): Promise<Conversation> {
  return request({ url: '/api/v1/im/conversations', method: 'POST', data: { user_id } })
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
