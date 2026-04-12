import { defineStore } from 'pinia'
import { getLostFoundList, type LostFound } from '../api/market'

export const useMarketStore = defineStore('market', {
  state: () => ({
    lostFoundList: [] as LostFound[],
    lostFoundTotal: 0,
    lostFoundPage: 1,
    lostFoundHasMore: true,
    activeTab: 'lost-found' as 'lost-found' | 'second-hand' | 'part-time' | 'barter',
  }),

  actions: {
    async loadLostFound(refresh = false) {
      if (refresh) {
        this.lostFoundPage = 1
        this.lostFoundHasMore = true
        this.lostFoundList = []
      }
      if (!this.lostFoundHasMore) return

      const res = await getLostFoundList({ page: this.lostFoundPage })
      this.lostFoundList = refresh ? res.items : [...this.lostFoundList, ...res.items]
      this.lostFoundTotal = res.total
      this.lostFoundHasMore = res.has_more
      this.lostFoundPage++
    },
  },
})
