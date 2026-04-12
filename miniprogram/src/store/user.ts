import { defineStore } from 'pinia'
import { request } from '../api/request'

export interface UserProfile {
  id: string
  username: string
  phone: string | null
  avatar_url: string | null
  bio: string | null
  gender: number
  birthday: string | null
  is_verified: boolean
  is_new_user: boolean
}

export interface UserStats {
  user_id: string
  growth_value: number
  points: number
  collect_count: number
  level: number
  credit_score: number
}

export const useUserStore = defineStore('user', {
  state: () => ({
    profile: null as UserProfile | null,
    stats: null as UserStats | null,
    isLoggedIn: false,
  }),

  getters: {
    creditLabel: (state) => {
      const score = state.stats?.credit_score ?? 0
      if (score >= 900) return '极佳'
      if (score >= 800) return '优秀'
      if (score >= 700) return '良好'
      return '普通'
    },
  },

  actions: {
    async fetchProfile() {
      this.profile = await request<UserProfile>({ url: '/api/v1/users/me' })
      this.isLoggedIn = true
    },

    async fetchStats() {
      this.stats = await request<UserStats>({ url: '/api/v1/users/me/stats' })
    },

    setTokens(access_token: string, refresh_token: string) {
      uni.setStorageSync('access_token', access_token)
      uni.setStorageSync('refresh_token', refresh_token)
      this.isLoggedIn = true
    },

    logout() {
      uni.removeStorageSync('access_token')
      uni.removeStorageSync('refresh_token')
      this.profile = null
      this.stats = null
      this.isLoggedIn = false
      uni.reLaunch({ url: '/pages/auth/login' })
    },
  },
})
