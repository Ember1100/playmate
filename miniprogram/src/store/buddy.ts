import { defineStore } from 'pinia'
import { getCandidates, getReceivedInvitations, type BuddyCandidate, type BuddyInvitation } from '../api/buddy'

export const useBuddyStore = defineStore('buddy', {
  state: () => ({
    candidates: [] as BuddyCandidate[],
    candidatesPage: 1,
    candidatesHasMore: true,
    activeType: 1 as 1 | 2 | 3,   // 1线上 2线下 3职业
    receivedInvitations: [] as BuddyInvitation[],
    pendingCount: 0,
  }),

  actions: {
    async loadCandidates(refresh = false) {
      if (refresh) {
        this.candidatesPage = 1
        this.candidatesHasMore = true
        this.candidates = []
      }
      if (!this.candidatesHasMore) return

      const res = await getCandidates(this.activeType, this.candidatesPage)
      this.candidates = refresh ? res.items : [...this.candidates, ...res.items]
      this.candidatesHasMore = res.has_more
      this.candidatesPage++
    },

    async loadReceivedInvitations() {
      const res = await getReceivedInvitations()
      this.receivedInvitations = res.items
      this.pendingCount = res.items.filter((i) => i.status === 0).length
    },

    setActiveType(type: 1 | 2 | 3) {
      this.activeType = type
      this.loadCandidates(true)
    },
  },
})
