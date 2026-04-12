import { onShow } from '@dcloudio/uni-app'

/**
 * 在每个 Tab 根页面的 <script setup> 中调用，通知自定义 tabBar 高亮对应项。
 * @param index  Tab 索引：0=圈子 1=集市 2=搭子 3=趣玩 4=我的
 */
export function useTabBar(index: number) {
  onShow(() => {
    const pages = getCurrentPages()
    const cur = pages[pages.length - 1] as any
    cur?.getTabBar?.()?.setIndex?.(index)
  })
}
