import { request } from './request'
import type { PageResponse } from './request'

export interface Topic {
  id: string
  creator_id: string
  title: string
  content: string | null
  cover_url: string | null
  category: string | null
  like_count: number
  comment_count: number
  view_count: number
  is_hot: boolean
  created_at: string
  creator?: { username: string; avatar_url: string | null }
  is_liked?: boolean
}

export interface TopicComment {
  id: string
  topic_id: string
  user_id: string
  parent_id: string | null
  content: string
  like_count: number
  created_at: string
  user?: { username: string; avatar_url: string | null }
}

export interface Poll {
  id: string
  creator_id: string
  title: string
  pro_argument: string
  con_argument: string
  pro_count: number
  con_count: number
  created_at: string
  my_vote?: 1 | 2 | null
}

// ── 话题 ──────────────────────────────────
export function getTopics(params?: { category?: string; page?: number }): Promise<PageResponse<Topic>> {
  const q = new URLSearchParams()
  if (params?.category) q.set('category', params.category)
  q.set('page', String(params?.page ?? 1))
  return request({ url: `/api/v1/topics?${q}` })
}

export function getTopic(id: string): Promise<Topic> {
  return request({ url: `/api/v1/topics/${id}` })
}

export function createTopic(data: Partial<Topic>): Promise<Topic> {
  return request({ url: '/api/v1/topics', method: 'POST', data })
}

export function likeTopic(id: string): Promise<void> {
  return request({ url: `/api/v1/topics/${id}/like`, method: 'POST' })
}

export function unlikeTopic(id: string): Promise<void> {
  return request({ url: `/api/v1/topics/${id}/like`, method: 'DELETE' })
}

export function getComments(topicId: string, page = 1): Promise<PageResponse<TopicComment>> {
  return request({ url: `/api/v1/topics/${topicId}/comments?page=${page}` })
}

export function postComment(topicId: string, content: string, parent_id?: string): Promise<TopicComment> {
  return request({ url: `/api/v1/topics/${topicId}/comments`, method: 'POST', data: { content, parent_id } })
}

// ── 投票 ──────────────────────────────────
export function getPolls(page = 1): Promise<PageResponse<Poll>> {
  return request({ url: `/api/v1/polls?page=${page}` })
}

export function votePoll(id: string, side: 1 | 2): Promise<void> {
  return request({ url: `/api/v1/polls/${id}/vote`, method: 'POST', data: { side } })
}

// ── 社群 ──────────────────────────────────
export function getGroups(page = 1): Promise<PageResponse<any>> {
  return request({ url: `/api/v1/circle/groups?page=${page}` })
}

export function joinGroup(id: string): Promise<void> {
  return request({ url: `/api/v1/circle/groups/${id}/join`, method: 'POST' })
}

export function getGroupMessages(id: string, page = 1): Promise<PageResponse<any>> {
  return request({ url: `/api/v1/circle/groups/${id}/messages?page=${page}` })
}
