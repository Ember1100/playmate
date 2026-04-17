<template>
  <view class="buddy">
    <!-- Header -->
    <view class="buddy__header">
      <text class="buddy__header-title">俱乐部兴趣活动</text>
    </view>

    <scroll-view scroll-y class="buddy__scroll">
      <!-- Banner -->
      <view class="buddy__banner-wrap">
        <view class="buddy__banner">
          <view class="buddy__cloud c1" />
          <view class="buddy__cloud c2" />
          <view class="buddy__cloud c3" />
          <view class="buddy__banner-text">
            <text class="buddy__banner-line">周末不宅</text>
            <text class="buddy__banner-line">组队去野</text>
          </view>
          <text class="buddy__owl">🦉</text>
          <text class="buddy__banner-indicator">1/1</text>
          <view class="buddy__banner-handle" />
        </view>
      </view>

      <!-- Search -->
      <view class="buddy__search-wrap" @click="uni.navigateTo({url:'/pages/buddy/search'})">
        <view class="buddy__search">
          <text class="buddy__search-icon">🔍</text>
          <text class="buddy__search-hint">请输入关键词</text>
        </view>
      </view>

      <!-- 三分类卡片 -->
      <view class="buddy__cat-section">
        <view class="buddy__cat-grid">
          <view class="buddy__cat-card online" @click="uni.navigateTo({url:'/pages/buddy/candidates?type=1'})">
            <view class="buddy__cat-content">
              <text class="buddy__cat-title">线上搭子</text>
              <text class="buddy__cat-desc">快速匹配</text>
            </view>
            <text class="buddy__cat-deco">💻</text>
          </view>
          <view class="buddy__cat-card pro" @click="uni.navigateTo({url:'/pages/buddy/career'})">
            <view class="buddy__cat-content">
              <text class="buddy__cat-title">职业搭子</text>
              <text class="buddy__cat-desc">您的专业老师</text>
            </view>
            <text class="buddy__cat-deco">💼</text>
          </view>
          <view class="buddy__cat-card offline" @click="uni.navigateTo({url:'/pages/buddy/candidates?type=2'})">
            <view class="buddy__cat-content">
              <text class="buddy__cat-title">线下搭子</text>
              <text class="buddy__cat-desc">按照需求进行匹配</text>
            </view>
            <text class="buddy__cat-deco">🤝</text>
          </view>
        </view>
      </view>

      <!-- ══ 搭子局区域 ══ -->

      <!-- 搭子局 Tab 栏 + 发起按钮 -->
      <view class="gather__topbar">
        <view style="flex:1" />
        <view class="gather__topbar-btn" @click="showPublish = true">
          <text class="gather__topbar-btn-icon">+</text>
          <text class="gather__topbar-btn-text">发起搭子局</text>
        </view>
      </view>

      <!-- 一级分类 Tab -->
      <scroll-view scroll-x :show-scrollbar="false" class="gather__cat-scroll">
        <view class="gather__cat-row">
          <view
            v-for="(cat, ci) in categories"
            :key="cat"
            :class="['gather__cat-item', ci === catIndex ? 'gather__cat-item--active' : '']"
            @click="onCatTap(ci)"
          >
            <text>{{ cat }}</text>
          </view>
        </view>
      </scroll-view>

      <!-- 二级子标签 -->
      <scroll-view scroll-x :show-scrollbar="false" class="gather__sub-scroll">
        <view class="gather__sub-row">
          <view
            v-for="(tag, ti) in currentSubTags"
            :key="tag"
            :class="['gather__sub-item', ti === subTagIndex ? 'gather__sub-item--active' : '']"
            @click="onSubTagTap(ti, tag)"
          >
            <text>{{ tag }}</text>
          </view>
        </view>
      </scroll-view>

      <!-- 搭子局卡片列表（一级分类，未选子标签） -->
      <view v-if="subTagIndex < 0" class="gather__list">
        <view
          v-for="item in currentGatherItems"
          :key="item.title"
          class="gather__card"
          @click="detailItem = item; showDetail = true"
        >
          <!-- 标题 + 主题标签 -->
          <view class="gather__card-header">
            <text class="gather__card-title">{{ item.title }}</text>
            <view class="gather__card-theme" :style="{ background: item.themeColor + '1F', borderColor: item.themeColor + '66' }">
              <text :style="{ color: item.themeColor }">{{ item.theme }}</text>
            </view>
          </view>
          <!-- 地点 -->
          <view class="gather__card-row">
            <text class="gather__card-icon" style="color:#999">📍</text>
            <text class="gather__card-text">{{ item.location }}</text>
          </view>
          <!-- 开始时间 -->
          <view class="gather__card-row">
            <text class="gather__card-icon" style="color:#5DCAA5">▶</text>
            <text class="gather__card-text">开始：{{ fmtTime(item.startTime) }}</text>
          </view>
          <!-- 结束时间 -->
          <view class="gather__card-row">
            <text class="gather__card-icon" style="color:#E24B4A">⏹</text>
            <text class="gather__card-text">结束：{{ fmtTime(item.endTime) }}</text>
          </view>
          <!-- 参与者 + 参加按钮 -->
          <view class="gather__card-footer">
            <view class="gather__card-avatars">
              <image
                v-for="(av, ai) in item.avatars"
                :key="ai"
                :src="av"
                class="gather__card-avatar"
                :style="{ marginLeft: ai > 0 ? '-16rpx' : '0' }"
                mode="aspectFill"
              />
            </view>
            <text class="gather__card-count">{{ item.joinedCount }}/{{ item.totalCount }} 人参加</text>
            <view class="gather__card-join-btn">
              <text>参加</text>
            </view>
          </view>
        </view>
      </view>

      <!-- 搭子人物网格（选中子标签时） -->
      <view v-else class="buddy-person__grid">
        <view
          v-for="person in currentBuddyPeople"
          :key="person.name"
          class="buddy-person__card"
          @click="uni.navigateTo({url:'/pages/buddy/detail?name='+person.name})"
        >
          <view class="buddy-person__img-wrap">
            <image :src="person.avatar" class="buddy-person__img" mode="aspectFill" />
            <view class="buddy-person__tag-badge">
              <text>{{ person.tag }}</text>
            </view>
          </view>
          <view class="buddy-person__info">
            <view class="buddy-person__name-row">
              <text class="buddy-person__name">{{ person.name }}</text>
              <text class="buddy-person__meta">{{ person.city }} · {{ person.age }}岁</text>
            </view>
            <text class="buddy-person__desc">{{ person.desc }}</text>
            <view class="buddy-person__invite-btn">
              <text>邀约</text>
            </view>
          </view>
        </view>
      </view>

      <view style="height: 48rpx" />
    </scroll-view>

    <!-- 搭子局详情弹窗 -->
    <view v-if="showDetail && detailItem" class="detail-mask" @click="showDetail = false" @touchmove.stop>
      <view class="detail-sheet" @click.stop @touchmove.stop>
        <view class="detail-sheet__handle" />
        <!-- 标题 -->
        <view class="detail-sheet__header">
          <text class="detail-sheet__title">{{ detailItem.title }}</text>
          <view class="detail-sheet__theme" :style="{ background: detailItem.themeColor + '1F', borderColor: detailItem.themeColor + '66' }">
            <text :style="{ color: detailItem.themeColor }">{{ detailItem.theme }}</text>
          </view>
        </view>
        <view class="detail-sheet__divider" />
        <!-- 信息 -->
        <view class="detail-sheet__body">
          <view class="detail-sheet__row">
            <text class="detail-sheet__row-icon" style="color:#FF7A00">📍</text>
            <view class="detail-sheet__row-content">
              <text class="detail-sheet__row-label">活动地点</text>
              <text class="detail-sheet__row-value">{{ detailItem.location }}</text>
            </view>
          </view>
          <view class="detail-sheet__row">
            <text class="detail-sheet__row-icon" style="color:#5DCAA5">▶</text>
            <view class="detail-sheet__row-content">
              <text class="detail-sheet__row-label">开始时间</text>
              <text class="detail-sheet__row-value">{{ fmtTime(detailItem.startTime) }}</text>
            </view>
          </view>
          <view class="detail-sheet__row">
            <text class="detail-sheet__row-icon" style="color:#E24B4A">⏹</text>
            <view class="detail-sheet__row-content">
              <text class="detail-sheet__row-label">结束时间</text>
              <text class="detail-sheet__row-value">{{ fmtTime(detailItem.endTime) }}</text>
            </view>
          </view>
          <!-- 参与者 -->
          <text class="detail-sheet__section-title">参加的搭子</text>
          <view class="detail-sheet__avatars">
            <image v-for="(av, ai) in detailItem.avatars" :key="ai" :src="av" class="detail-sheet__avatar" mode="aspectFill" />
            <view v-for="n in Math.min(detailItem.totalCount - detailItem.joinedCount, 3)" :key="'e'+n" class="detail-sheet__avatar-empty">
              <text>+</text>
            </view>
          </view>
          <text class="detail-sheet__count">已参加 {{ detailItem.joinedCount }} 人，共 {{ detailItem.totalCount }} 个名额</text>
        </view>
        <!-- 底部按钮 -->
        <view class="detail-sheet__footer">
          <view class="detail-sheet__join-btn" @click="showDetail = false">
            <text>立即参加（{{ detailItem.joinedCount }}/{{ detailItem.totalCount }}）</text>
          </view>
        </view>
      </view>
    </view>

    <!-- 发起搭子局弹窗 -->
    <view v-if="showPublish" class="detail-mask" @click="showPublish = false" @touchmove.stop>
      <view class="publish-sheet" @click.stop @touchmove.stop>
        <!-- 标题栏 -->
        <view class="publish-sheet__header">
          <text class="publish-sheet__title">发起搭子局</text>
          <text class="publish-sheet__close" @click="showPublish = false">✕</text>
        </view>
        <view class="detail-sheet__divider" />
        <scroll-view scroll-y class="publish-sheet__body" @touchmove.stop>
          <!-- 普通文本字段 -->
          <view class="publish-sheet__field" v-for="f in publishTextFields" :key="f.label">
            <text class="publish-sheet__label">{{ f.label }}</text>
            <input class="publish-sheet__input" :placeholder="f.hint" :type="f.inputType ?? 'text'" />
          </view>

          <!-- 开始时间 -->
          <view class="publish-sheet__field">
            <text class="publish-sheet__label">开始时间</text>
            <picker mode="datetime" :value="startTimeRaw" @change="onStartTimeChange">
              <view class="publish-sheet__picker">
                <text :class="startTimeDisplay ? 'publish-sheet__picker-val' : 'publish-sheet__picker-hint'">
                  {{ startTimeDisplay || '请选择开始时间' }}
                </text>
                <text class="publish-sheet__picker-arrow">›</text>
              </view>
            </picker>
          </view>

          <!-- 结束时间 -->
          <view class="publish-sheet__field">
            <text class="publish-sheet__label">结束时间</text>
            <picker mode="datetime" :value="endTimeRaw" @change="onEndTimeChange">
              <view class="publish-sheet__picker">
                <text :class="endTimeDisplay ? 'publish-sheet__picker-val' : 'publish-sheet__picker-hint'">
                  {{ endTimeDisplay || '请选择结束时间' }}
                </text>
                <text class="publish-sheet__picker-arrow">›</text>
              </view>
            </picker>
          </view>

          <!-- 人数 + 主题 -->
          <view class="publish-sheet__field" v-for="f in publishTailFields" :key="f.label">
            <text class="publish-sheet__label">{{ f.label }}</text>
            <input class="publish-sheet__input" :placeholder="f.hint" :type="f.inputType ?? 'text'" />
          </view>

          <view class="publish-sheet__submit" @click="showPublish = false">
            <text>发布搭子局</text>
          </view>
        </scroll-view>
      </view>
    </view>

    <!-- FAB -->
    <view class="buddy__fab-stack">
      <view class="buddy__fab" @click="uni.navigateTo({url:'/pages/buddy/invitations'})">
        <text class="buddy__fab-icon">📋</text>
      </view>
      <view class="buddy__fab" @click="uni.navigateTo({url:'/pages/im/chat'})">
        <text class="buddy__fab-icon">💬</text>
      </view>
    </view>
  </view>
  <PmTabBar :current="2" />
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import PmTabBar from '@/components/PmTabBar.vue'

// ── 搭子局分类 ──
const categories = ['生活', '学习', '兴趣', '游戏', '自定义']
const catIndex = ref(0)
const subTagIndex = ref(-1) // -1 = 显示搭子局；>=0 = 显示搭子人物

const subTagsMap: Record<string, string[]> = {
  '生活': ['饭搭子', '探店搭子', '遛宠搭子', '观影搭子', '健身搭子', '更多...'],
  '学习': ['考研搭子', '刷题搭子', '图书馆搭子', '语言搭子', '更多...'],
  '兴趣': ['摄影搭子', '手工搭子', '读书搭子', '音乐搭子', '更多...'],
  '游戏': ['手游搭子', '桌游搭子', '剧本杀搭子', 'Steam搭子', '更多...'],
  '自定义': ['我发起的', '我参与的'],
}

const currentSubTags = computed(() => subTagsMap[categories[catIndex.value]] || [])

function onCatTap(ci: number) {
  catIndex.value = ci
  subTagIndex.value = -1
}

function onSubTagTap(ti: number, tag: string) {
  if (tag === '更多...') return
  subTagIndex.value = subTagIndex.value === ti ? -1 : ti
}

// ── 时间格式化 ──
interface TimeObj { year: number; month: number; day: number; hour: number; minute: number; second: number }

function fmtTime(t: TimeObj): string {
  const p = (n: number) => n.toString().padStart(2, '0')
  return `${t.year}年${p(t.month)}月${p(t.day)}日 ${p(t.hour)}:${p(t.minute)}:${p(t.second)}`
}

// ── 搭子局模拟数据 ──
interface GatherItem {
  title: string; location: string; startTime: TimeObj; endTime: TimeObj
  theme: string; themeColor: string; joinedCount: number; totalCount: number; avatars: string[]
}

const gatherData: Record<string, GatherItem[]> = {
  '生活': [
    { title: '周末饭局 · 探秘地道川菜', location: '上海市黄浦区南京东路888号', startTime: { year: 2026, month: 4, day: 19, hour: 18, minute: 30, second: 0 }, endTime: { year: 2026, month: 4, day: 19, hour: 21, minute: 0, second: 0 }, theme: '饭搭子', themeColor: '#FF7A00', joinedCount: 4, totalCount: 8, avatars: ['https://picsum.photos/seed/u1/40/40', 'https://picsum.photos/seed/u2/40/40', 'https://picsum.photos/seed/u3/40/40'] },
    { title: '遛猫下午茶 · 宠物友好咖啡馆', location: '上海市徐汇区衡山路12号', startTime: { year: 2026, month: 4, day: 20, hour: 14, minute: 0, second: 0 }, endTime: { year: 2026, month: 4, day: 20, hour: 17, minute: 0, second: 0 }, theme: '遛宠搭子', themeColor: '#5DCAA5', joinedCount: 2, totalCount: 6, avatars: ['https://picsum.photos/seed/u4/40/40', 'https://picsum.photos/seed/u5/40/40'] },
    { title: '周五观影 · 《流浪地球3》首映', location: '上海市浦东新区张江CGV影城', startTime: { year: 2026, month: 4, day: 18, hour: 19, minute: 40, second: 0 }, endTime: { year: 2026, month: 4, day: 18, hour: 22, minute: 0, second: 0 }, theme: '观影搭子', themeColor: '#9C27B0', joinedCount: 5, totalCount: 10, avatars: ['https://picsum.photos/seed/u6/40/40', 'https://picsum.photos/seed/u7/40/40', 'https://picsum.photos/seed/u8/40/40'] },
  ],
  '学习': [
    { title: '考研备战 · 图书馆打卡团', location: '上海图书馆东馆（陆家嘴）', startTime: { year: 2026, month: 4, day: 16, hour: 9, minute: 0, second: 0 }, endTime: { year: 2026, month: 4, day: 16, hour: 18, minute: 0, second: 0 }, theme: '考研搭子', themeColor: '#2196F3', joinedCount: 6, totalCount: 10, avatars: ['https://picsum.photos/seed/s1/40/40', 'https://picsum.photos/seed/s2/40/40'] },
    { title: '英语角 · 外教口语练习', location: '上海市静安区南京西路1788号', startTime: { year: 2026, month: 4, day: 17, hour: 19, minute: 0, second: 0 }, endTime: { year: 2026, month: 4, day: 17, hour: 21, minute: 0, second: 0 }, theme: '语言搭子', themeColor: '#4CAF50', joinedCount: 3, totalCount: 8, avatars: ['https://picsum.photos/seed/s3/40/40'] },
  ],
  '兴趣': [
    { title: '街头摄影 · 外滩黄金时刻', location: '上海市黄浦区中山东一路外滩', startTime: { year: 2026, month: 4, day: 19, hour: 17, minute: 30, second: 0 }, endTime: { year: 2026, month: 4, day: 19, hour: 20, minute: 0, second: 0 }, theme: '摄影搭子', themeColor: '#E91E63', joinedCount: 3, totalCount: 6, avatars: ['https://picsum.photos/seed/h1/40/40', 'https://picsum.photos/seed/h2/40/40'] },
  ],
  '游戏': [
    { title: '剧本杀 · 悬疑推理专场', location: '上海市杨浦区五角场线索屋', startTime: { year: 2026, month: 4, day: 20, hour: 13, minute: 0, second: 0 }, endTime: { year: 2026, month: 4, day: 20, hour: 18, minute: 0, second: 0 }, theme: '剧本杀搭子', themeColor: '#795548', joinedCount: 4, totalCount: 6, avatars: ['https://picsum.photos/seed/g1/40/40', 'https://picsum.photos/seed/g2/40/40', 'https://picsum.photos/seed/g3/40/40'] },
  ],
}

const currentGatherItems = computed(() => gatherData[categories[catIndex.value]] || [])

// ── 搭子人物模拟数据 ──
interface BuddyPerson { name: string; age: number; city: string; avatar: string; desc: string; tag: string }

const buddyPeopleMap: Record<string, BuddyPerson[]> = {
  '饭搭子': [
    { name: '小鱼', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p1/200/200', desc: '爱吃川菜，周末约饭', tag: '饭搭子' },
    { name: '阿杰', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/p2/200/200', desc: '探店达人，火锅爱好者', tag: '饭搭子' },
    { name: '甜甜', age: 22, city: '上海', avatar: 'https://picsum.photos/seed/p3/200/200', desc: '甜品控，周末想约下午茶', tag: '饭搭子' },
    { name: '大壮', age: 27, city: '上海', avatar: 'https://picsum.photos/seed/p4/200/200', desc: '烧烤达人，自带装备', tag: '饭搭子' },
  ],
  '探店搭子': [
    { name: '小薇', age: 24, city: '上海', avatar: 'https://picsum.photos/seed/p5/200/200', desc: '咖啡探店，拍照达人', tag: '探店搭子' },
    { name: '浩哥', age: 26, city: '上海', avatar: 'https://picsum.photos/seed/p6/200/200', desc: '美食博主，寻找新店', tag: '探店搭子' },
  ],
  '遛宠搭子': [
    { name: '毛毛妈', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/p7/200/200', desc: '金毛家长，周末公园遛弯', tag: '遛宠搭子' },
    { name: '猫叔', age: 28, city: '上海', avatar: 'https://picsum.photos/seed/p8/200/200', desc: '三只猫主人，猫咖常客', tag: '遛宠搭子' },
    { name: '柯基控', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p9/200/200', desc: '柯基爸爸，寻遛狗伙伴', tag: '遛宠搭子' },
  ],
  '观影搭子': [
    { name: '影迷小李', age: 24, city: '上海', avatar: 'https://picsum.photos/seed/p10/200/200', desc: '科幻迷，每周必看新片', tag: '观影搭子' },
    { name: '文艺青年', age: 26, city: '上海', avatar: 'https://picsum.photos/seed/p11/200/200', desc: '独立电影爱好者', tag: '观影搭子' },
  ],
  '考研搭子': [
    { name: '学霸小陈', age: 22, city: '上海', avatar: 'https://picsum.photos/seed/p12/200/200', desc: '备战27考研，每天图书馆', tag: '考研搭子' },
    { name: '阿文', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p13/200/200', desc: '二战考研，互相监督', tag: '考研搭子' },
    { name: '小月', age: 21, city: '上海', avatar: 'https://picsum.photos/seed/p14/200/200', desc: '法硕备考，求研友', tag: '考研搭子' },
  ],
  '摄影搭子': [
    { name: '阿光', age: 27, city: '上海', avatar: 'https://picsum.photos/seed/p15/200/200', desc: '风光摄影，周末扫街', tag: '摄影搭子' },
    { name: '小美', age: 24, city: '上海', avatar: 'https://picsum.photos/seed/p16/200/200', desc: '人像摄影，互拍互修', tag: '摄影搭子' },
  ],
  '剧本杀搭子': [
    { name: '推理王', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/p17/200/200', desc: '硬核推理，百本+经验', tag: '剧本杀搭子' },
    { name: '戏精本精', age: 23, city: '上海', avatar: 'https://picsum.photos/seed/p18/200/200', desc: '情感本爱好者，喜欢沉浸式', tag: '剧本杀搭子' },
    { name: '新手小白', age: 22, city: '上海', avatar: 'https://picsum.photos/seed/p19/200/200', desc: '刚入坑，求带飞', tag: '剧本杀搭子' },
  ],
}

const currentBuddyPeople = computed(() => {
  const tags = currentSubTags.value
  if (subTagIndex.value < 0 || subTagIndex.value >= tags.length) return []
  const tag = tags[subTagIndex.value]
  return buddyPeopleMap[tag] || [{ name: '搭伴用户', age: 25, city: '上海', avatar: 'https://picsum.photos/seed/pd/200/200', desc: '期待与你相遇', tag: '搭子' }]
})

// ── 弹窗状态 ──
const showDetail = ref(false)
const detailItem = ref<GatherItem | null>(null)
const showPublish = ref(false)

// 时间前两个普通字段
const publishTextFields = [
  { label: '活动名称', hint: '给你的搭子局起个名字' },
  { label: '活动地点', hint: '输入详细地址' },
]
// 时间后两个普通字段
const publishTailFields = [
  { label: '人数上限', hint: '最多几人参加（2-50）', inputType: 'number' },
  { label: '活动主题', hint: '饭搭子 / 观影搭子 / 其他...' },
]

// picker 的 value 格式：YYYY-MM-DD HH:mm
const startTimeRaw = ref('')
const endTimeRaw   = ref('')

function fmtPickerVal(raw: string): string {
  // raw: "2026-04-19 18:30" → "2026年04月月19日 18:30"
  if (!raw) return ''
  const [datePart, timePart] = raw.split(' ')
  const [y, m, d] = datePart.split('-')
  return `${y}年${m}月${d}日 ${timePart}`
}

const startTimeDisplay = computed(() => fmtPickerVal(startTimeRaw.value))
const endTimeDisplay   = computed(() => fmtPickerVal(endTimeRaw.value))

function onStartTimeChange(e: any) {
  startTimeRaw.value = e.detail.value
  // 结束时间若早于开始时间，自动顺延 2 小时
  if (endTimeRaw.value && endTimeRaw.value < startTimeRaw.value) {
    const d = new Date(startTimeRaw.value.replace(' ', 'T'))
    d.setHours(d.getHours() + 2)
    const pad = (n: number) => String(n).padStart(2, '0')
    endTimeRaw.value = `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
  }
}

function onEndTimeChange(e: any) {
  endTimeRaw.value = e.detail.value
}
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.buddy {
  min-height: 100vh;
  background-color: $color-bg;
  position: relative;

  // ── Header ──
  &__header {
    display: flex; align-items: center; justify-content: center;
    height: 88rpx; background: #fff; border-bottom: 2rpx solid #f0f0f0;
  }
  &__header-title { font-size: $font-lg; font-weight: 700; color: #222; }
  &__scroll { height: calc(100vh - 88rpx - 98px); }

  // ── Banner ──
  &__banner-wrap { padding: 20rpx 24rpx 0; }
  &__banner {
    position: relative; height: 296rpx; border-radius: 36rpx; overflow: hidden;
    background: linear-gradient(165deg, #FFE8C0 0%, #FFD166 45%, #FFB703 100%);
  }
  &__cloud {
    position: absolute; background: rgba(255,255,255,0.85); border-radius: 50%;
    &.c1 { width: 144rpx; height: 72rpx; top: 24rpx; left: 8%; }
    &.c2 { width: 112rpx; height: 56rpx; top: 48rpx; left: 28%; opacity: 0.9; }
    &.c3 { width: 128rpx; height: 64rpx; top: 16rpx; right: 22%; }
  }
  &__banner-text {
    position: absolute; left: 32rpx; top: 50%; transform: translateY(-50%); z-index: 2;
    display: flex; flex-direction: column;
  }
  &__banner-line {
    font-size: $font-2xl; font-weight: 900; color: #333; letter-spacing: 2rpx; line-height: 1.25;
    text-shadow: 0 2rpx 0 rgba(255,255,255,0.6);
  }
  &__owl { position: absolute; right: 20rpx; bottom: 16rpx; font-size: 120rpx; z-index: 1; line-height: 1; }
  &__banner-indicator { position: absolute; right: 20rpx; bottom: 16rpx; font-size: $font-xs; color: rgba(0,0,0,0.45); z-index: 3; }
  &__banner-handle {
    position: absolute; left: 50%; bottom: 8rpx; transform: translateX(-50%);
    width: 72rpx; height: 8rpx; background: rgba(0,0,0,0.12); border-radius: 4rpx; z-index: 3;
  }

  // ── Search ──
  &__search-wrap { padding: 24rpx 28rpx 20rpx; }
  &__search {
    display: flex; align-items: center; gap: 16rpx;
    background: #FFE8C0; border-radius: 999rpx; padding: 20rpx 32rpx;
  }
  &__search-icon { font-size: $font-lg; opacity: 0.6; }
  &__search-hint { font-size: $font-base; color: #9e9e9e; }

  // ── Category Grid ──
  &__cat-section { padding: 12rpx 24rpx 24rpx; }
  &__cat-grid {
    display: grid; grid-template-columns: 1fr 1fr; grid-template-rows: 192rpx 192rpx; gap: 20rpx;
  }
  &__cat-card {
    border-radius: 36rpx; position: relative; overflow: hidden;
    box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.06); display: flex; flex-direction: column;
    &.online  { grid-column: 1; grid-row: 1; background: #FFE8C0; }
    &.offline { grid-column: 1; grid-row: 2; background: #FFE082; }
    &.pro     { grid-column: 2; grid-row: 1 / span 2; background: #FFE8C0; }
  }
  &__cat-content {
    position: absolute; left: 28rpx; top: 28rpx; z-index: 2;
    display: flex; flex-direction: column; gap: 8rpx;
  }
  &__cat-title { font-size: $font-lg; font-weight: 700; color: #222; }
  &__cat-desc { font-size: $font-xs; color: #666; line-height: 1.4; }
  &__cat-deco {
    position: absolute; right: 16rpx; bottom: 16rpx; font-size: 96rpx; line-height: 1; opacity: 0.85; z-index: 1;
  }

  // ── FAB ──
  &__fab-stack {
    position: fixed; right: 20rpx; bottom: calc(98px + 172rpx);
    display: flex; flex-direction: column; gap: 20rpx; z-index: 50;
  }
  &__fab {
    width: 88rpx; height: 88rpx; border-radius: 50%; background: #fff;
    box-shadow: 0 4rpx 24rpx rgba(0,0,0,0.1);
    display: flex; align-items: center; justify-content: center;
  }
  &__fab-icon { font-size: $font-xl; }
}

// ══════════════════════════════════════════════════════════
//  搭子局区域
// ══════════════════════════════════════════════════════════

.gather {
  &__topbar {
    display: flex; align-items: center; height: 100rpx; padding: 0 32rpx; background: #fff;
  }
  &__topbar-tab { display: flex; flex-direction: column; align-items: center; }
  &__topbar-label {
    font-size: 32rpx; font-weight: 400; color: #999;
    &--active { font-weight: 700; color: #222; }
  }
  &__topbar-indicator {
    margin-top: 4rpx; width: 48rpx; height: 6rpx; border-radius: 4rpx; background: #FF7A00;
  }
  &__topbar-btn {
    display: flex; align-items: center; gap: 8rpx;
    padding: 12rpx 24rpx; background: #FF7A00; border-radius: 40rpx;
  }
  &__topbar-btn-icon { color: #fff; font-size: 28rpx; font-weight: 700; }
  &__topbar-btn-text { color: #fff; font-size: 26rpx; font-weight: 600; }

  // ── 一级分类 ──
  &__cat-scroll { background: #fff; white-space: nowrap; }
  &__cat-row { display: flex; gap: 8rpx; padding: 12rpx 24rpx; }
  &__cat-item {
    flex-shrink: 0; padding: 16rpx 28rpx; border-radius: 40rpx; font-size: 28rpx; color: #666;
    &--active { background: #FF7A00; color: #fff; font-weight: 700; }
  }

  // ── 二级子标签 ──
  &__sub-scroll { background: $color-bg; white-space: nowrap; }
  &__sub-row { display: flex; gap: 16rpx; padding: 16rpx 24rpx; }
  &__sub-item {
    flex-shrink: 0; padding: 10rpx 24rpx; background: #fff; border-radius: 32rpx;
    border: 2rpx solid #eee; font-size: 24rpx; color: #666;
    &--active { background: #FFEDD0; border-color: #FF7A00; color: #FF7A00; font-weight: 600; }
  }

  // ── 搭子局卡片 ──
  &__list { padding: 20rpx 24rpx 0; }
  &__card {
    background: #fff; border-radius: 28rpx; padding: 28rpx; margin-bottom: 24rpx;
    box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.05);
  }
  &__card-header { display: flex; align-items: flex-start; justify-content: space-between; }
  &__card-title { font-size: 30rpx; font-weight: 700; color: #222; line-height: 1.4; flex: 1; }
  &__card-theme {
    margin-left: 16rpx; padding: 6rpx 16rpx; border-radius: 20rpx;
    border: 2rpx solid; font-size: 22rpx; font-weight: 600; flex-shrink: 0;
  }
  &__card-row { display: flex; align-items: center; gap: 8rpx; margin-top: 12rpx; }
  &__card-icon { font-size: 24rpx; width: 28rpx; text-align: center; }
  &__card-text { font-size: 24rpx; color: #555; }
  &__card-footer { display: flex; align-items: center; margin-top: 20rpx; }
  &__card-avatars { display: flex; }
  &__card-avatar {
    width: 56rpx; height: 56rpx; border-radius: 50%; border: 4rpx solid #fff; background: #f5f5f5;
  }
  &__card-count { font-size: 24rpx; color: #888; margin-left: 16rpx; }
  &__card-join-btn {
    margin-left: auto; padding: 12rpx 32rpx; background: #FF7A00; border-radius: 32rpx;
    color: #fff; font-size: 26rpx; font-weight: 600;
  }
}

// ══════════════════════════════════════════════════════════
//  搭子人物网格
// ══════════════════════════════════════════════════════════

.buddy-person {
  &__grid {
    display: grid; grid-template-columns: 1fr 1fr; gap: 20rpx; padding: 20rpx 24rpx 0;
  }
  &__card {
    background: #fff; border-radius: 32rpx; overflow: hidden;
    box-shadow: 0 4rpx 16rpx rgba(0,0,0,0.05);
  }
  &__img-wrap { position: relative; width: 100%; aspect-ratio: 1; }
  &__img { width: 100%; height: 100%; display: block; background: #f5f5f5; }
  &__tag-badge {
    position: absolute; top: 16rpx; left: 16rpx;
    padding: 6rpx 16rpx; background: rgba(255,122,0,0.9); border-radius: 20rpx;
    color: #fff; font-size: 20rpx; font-weight: 600;
  }
  &__info { padding: 20rpx; }
  &__name-row { display: flex; align-items: baseline; gap: 12rpx; }
  &__name { font-size: 28rpx; font-weight: 700; color: #222; }
  &__meta { font-size: 22rpx; color: #999; }
  &__desc {
    font-size: 22rpx; color: #888; margin-top: 8rpx; line-height: 1.4;
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }
  &__invite-btn {
    margin-top: 12rpx; width: 100%; height: 56rpx; background: #FF7A00; border-radius: 28rpx;
    display: flex; align-items: center; justify-content: center;
    color: #fff; font-size: 24rpx; font-weight: 600;
  }
}

// ══════════════════════════════════════════════════════════
//  详情弹窗 & 发起弹窗
// ══════════════════════════════════════════════════════════

.detail-mask {
  position: fixed; top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.45); z-index: 100;
  display: flex; align-items: flex-end;
}

.detail-sheet {
  width: 100%; max-height: 70vh; background: #fff;
  border-radius: 40rpx 40rpx 0 0; display: flex; flex-direction: column;

  &__handle {
    width: 72rpx; height: 8rpx; background: #ddd; border-radius: 4rpx;
    margin: 24rpx auto 0;
  }
  &__header {
    display: flex; align-items: flex-start; justify-content: space-between;
    padding: 32rpx 40rpx 0;
  }
  &__title { font-size: 36rpx; font-weight: 700; color: #222; flex: 1; }
  &__theme {
    margin-left: 20rpx; padding: 8rpx 20rpx; border-radius: 24rpx;
    border: 2rpx solid; font-size: 24rpx; font-weight: 600; flex-shrink: 0;
  }
  &__divider { height: 2rpx; background: #f0f0f0; margin: 32rpx 0 0; }
  &__body { padding: 32rpx 40rpx; overflow-y: auto; flex: 1; }
  &__row { display: flex; align-items: flex-start; gap: 20rpx; margin-bottom: 32rpx; }
  &__row-icon { font-size: 36rpx; }
  &__row-content { display: flex; flex-direction: column; gap: 4rpx; }
  &__row-label { font-size: 24rpx; color: #999; }
  &__row-value { font-size: 28rpx; color: #333; font-weight: 500; }
  &__section-title { font-size: 30rpx; font-weight: 700; color: #333; margin-bottom: 24rpx; }
  &__avatars { display: flex; gap: 16rpx; margin-bottom: 16rpx; }
  &__avatar {
    width: 80rpx; height: 80rpx; border-radius: 50%; border: 4rpx solid #eee; background: #f5f5f5;
  }
  &__avatar-empty {
    width: 80rpx; height: 80rpx; border-radius: 50%; border: 3rpx dashed #ddd; background: #f5f5f5;
    display: flex; align-items: center; justify-content: center; color: #ccc; font-size: 32rpx;
  }
  &__count { font-size: 26rpx; color: #888; }
  &__footer {
    padding: 24rpx 40rpx 48rpx; border-top: 2rpx solid #f0f0f0;
  }
  &__join-btn {
    width: 100%; height: 96rpx; background: #FF7A00; border-radius: 24rpx;
    display: flex; align-items: center; justify-content: center;
    color: #fff; font-size: 32rpx; font-weight: 700;
  }
}

.publish-sheet {
  width: 100%; max-height: 85vh; background: #fff;
  border-radius: 40rpx 40rpx 0 0; display: flex; flex-direction: column;

  &__header {
    display: flex; align-items: center; justify-content: center;
    position: relative; padding: 32rpx 32rpx 0;
  }
  &__title {
    font-size: 34rpx; font-weight: 700; color: #222;
  }
  &__close {
    position: absolute; right: 32rpx; top: 50%; transform: translateY(-50%);
    font-size: 36rpx; color: #999; padding: 8rpx;
  }
  &__body { padding: 32rpx 40rpx; overflow-y: auto; flex: 1; }
  &__field { margin-bottom: 32rpx; }
  &__label { font-size: 28rpx; font-weight: 600; color: #333; display: block; margin-bottom: 16rpx; }
  &__input {
    width: 100%; height: 88rpx; background: #f7f7f7; border-radius: 20rpx;
    padding: 0 28rpx; font-size: 28rpx; color: #333;
  }
  &__picker {
    width: 100%; height: 88rpx; background: #f7f7f7; border-radius: 20rpx;
    padding: 0 28rpx; display: flex; align-items: center; justify-content: space-between;
  }
  &__picker-val  { font-size: 28rpx; color: #333; flex: 1; }
  &__picker-hint { font-size: 28rpx; color: #BBBBBB; flex: 1; }
  &__picker-arrow { font-size: 36rpx; color: #BBBBBB; }
  &__submit {
    width: 100%; height: 96rpx; background: #FF7A00; border-radius: 24rpx;
    display: flex; align-items: center; justify-content: center;
    color: #fff; font-size: 32rpx; font-weight: 700; margin-top: 32rpx;
  }
}
</style>
