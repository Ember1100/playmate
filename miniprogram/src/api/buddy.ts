import { request } from './request'
import type { PageResponse } from './request'

export interface BuddyCandidate {
  id: string
  username: string
  avatar_url: string | null
  bio: string | null
  credit_score: number
  tags: string[]
  career_title: string | null
}

export interface BuddyInvitation {
  id: string
  from_user_id: string
  to_user_id: string
  title: string
  content: string | null
  activity_type: string | null
  scheduled_at: string | null
  location: string | null
  status: number   // 0待响应 1已接受 2已拒绝 3已过期
  created_at: string
}

// 搭子推荐列表（type: 1线上 2线下 3职业）
export function getCandidates(type = 1, page = 1): Promise<PageResponse<BuddyCandidate>> {
  return request({ url: `/api/v1/buddy/candidates?type=${type}&page=${page}` })
}

// 发起搭子请求
export function sendBuddyRequest(to_user_id: string, type: number, message?: string): Promise<void> {
  return request({ url: '/api/v1/buddy/request', method: 'POST', data: { to_user_id, type, message } })
}

// 响应搭子请求
export function respondBuddyRequest(id: string, accept: boolean): Promise<void> {
  return request({ url: `/api/v1/buddy/request/${id}/respond`, method: 'PUT', data: { accept } })
}

// 发送邀约
export function sendInvitation(payload: Partial<BuddyInvitation>): Promise<void> {
  return request({ url: '/api/v1/buddy/invitations', method: 'POST', data: payload })
}

// 我发出的邀约
export function getSentInvitations(page = 1): Promise<PageResponse<BuddyInvitation>> {
  return request({ url: `/api/v1/buddy/invitations/sent?page=${page}` })
}

// 我收到的邀约
export function getReceivedInvitations(page = 1): Promise<PageResponse<BuddyInvitation>> {
  return request({ url: `/api/v1/buddy/invitations/received?page=${page}` })
}

// 响应邀约
export function respondInvitation(id: string, accept: boolean): Promise<void> {
  return request({ url: `/api/v1/buddy/invitations/${id}/respond`, method: 'PUT', data: { accept } })
}

// 职业搭子阵地列表
export function getCareerProfiles(page = 1): Promise<PageResponse<any>> {
  return request({ url: `/api/v1/buddy/career?page=${page}` })
}
