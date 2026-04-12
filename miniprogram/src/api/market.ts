import { request } from './request'
import type { PageResponse } from './request'

export interface LostFound {
  id: string
  user_id: string
  type: number          // 1失物 2招领
  title: string
  description: string | null
  images: string[]
  category: string | null
  location: string | null
  contact: string | null
  status: number        // 1发布中 2已解决
  serial_no: string
  view_count: number
  created_at: string
}

export interface SecondHand {
  id: string
  user_id: string
  title: string
  description: string | null
  images: string[]
  price: number
  category: string | null
  condition: number     // 1全新 2九成新 3八成新 4其他
  location: string | null
  contact: string | null
  status: number        // 1在售 2已售
  view_count: number
  created_at: string
}

export interface PartTime {
  id: string
  user_id: string
  title: string
  description: string | null
  images: string[]
  salary: string | null
  salary_type: number   // 1按天 2按小时 3按次 4面议
  category: string | null
  location: string | null
  contact: string | null
  status: number        // 1招募中 2已结束
  view_count: number
  created_at: string
}

export interface Barter {
  id: string
  user_id: string
  title: string
  description: string | null
  images: string[]
  offer_item: string
  want_item: string
  category: string | null
  location: string | null
  contact: string | null
  status: number        // 1换物中 2已完成
  view_count: number
  created_at: string
}

// ── 失物招领 ───────────────────────────────
export function getLostFoundList(params?: { type?: number; category?: string; keyword?: string; page?: number }): Promise<PageResponse<LostFound>> {
  const q = new URLSearchParams()
  if (params?.type)     q.set('type', String(params.type))
  if (params?.category) q.set('category', params.category)
  if (params?.keyword)  q.set('keyword', params.keyword)
  q.set('page', String(params?.page ?? 1))
  return request({ url: `/api/v1/market/lost-found?${q}` })
}

export function getLostFound(id: string): Promise<LostFound> {
  return request({ url: `/api/v1/market/lost-found/${id}` })
}

export function publishLostFound(data: Partial<LostFound>): Promise<LostFound> {
  return request({ url: '/api/v1/market/lost-found', method: 'POST', data })
}

export function resolveLostFound(id: string): Promise<void> {
  return request({ url: `/api/v1/market/lost-found/${id}/resolve`, method: 'POST' })
}

// ── 二手闲置 ───────────────────────────────
export function getSecondHandList(params?: { category?: string; page?: number }): Promise<PageResponse<SecondHand>> {
  const q = new URLSearchParams()
  if (params?.category) q.set('category', params.category)
  q.set('page', String(params?.page ?? 1))
  return request({ url: `/api/v1/market/second-hand?${q}` })
}

export function getSecondHand(id: string): Promise<SecondHand> {
  return request({ url: `/api/v1/market/second-hand/${id}` })
}

export function publishSecondHand(data: Partial<SecondHand>): Promise<SecondHand> {
  return request({ url: '/api/v1/market/second-hand', method: 'POST', data })
}

// ── 兼职啦 ────────────────────────────────
export function getPartTimeList(params?: { category?: string; page?: number }): Promise<PageResponse<PartTime>> {
  const q = new URLSearchParams()
  if (params?.category) q.set('category', params.category)
  q.set('page', String(params?.page ?? 1))
  return request({ url: `/api/v1/market/part-time?${q}` })
}

export function getPartTime(id: string): Promise<PartTime> {
  return request({ url: `/api/v1/market/part-time/${id}` })
}

export function publishPartTime(data: Partial<PartTime>): Promise<PartTime> {
  return request({ url: '/api/v1/market/part-time', method: 'POST', data })
}

// ── 以物换物 ──────────────────────────────
export function getBarterList(page = 1): Promise<PageResponse<Barter>> {
  return request({ url: `/api/v1/market/barter?page=${page}` })
}

export function getBarter(id: string): Promise<Barter> {
  return request({ url: `/api/v1/market/barter/${id}` })
}

export function publishBarter(data: Partial<Barter>): Promise<Barter> {
  return request({ url: '/api/v1/market/barter', method: 'POST', data })
}

// ── 收藏 ─────────────────────────────────
export function addCollect(target_type: string, target_id: string): Promise<void> {
  return request({ url: '/api/v1/market/collect', method: 'POST', data: { target_type, target_id } })
}

export function removeCollect(target_type: string, target_id: string): Promise<void> {
  return request({ url: '/api/v1/market/collect', method: 'DELETE', data: { target_type, target_id } })
}

export function getMyCollects(): Promise<any[]> {
  return request({ url: '/api/v1/market/collect/mine' })
}
