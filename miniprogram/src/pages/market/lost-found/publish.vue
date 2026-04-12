<template>
  <view class="publish">
    <!-- 顶部导航 -->
    <view class="publish__nav">
      <view class="publish__back" @click="uni.navigateBack()">
        <text class="publish__back-icon">〈</text>
      </view>
      <text class="publish__title">发布失物</text>
      <view class="publish__nav-right">
        <view class="publish__dot-btn">
          <view class="publish__dot" />
          <view class="publish__dot" />
          <view class="publish__dot" />
        </view>
      </view>
    </view>

    <scroll-view scroll-y class="publish__scroll">
      <view class="publish__card">
        <!-- 基础信息 -->
        <text class="publish__section-title">基础信息</text>

        <view class="publish__row">
          <input
            class="publish__input"
            v-model="form.title"
            placeholder="物品名称"
            placeholder-class="publish__placeholder"
          />
          <picker mode="date" :value="form.lostDate" @change="onDateChange">
            <view class="publish__input publish__date-picker">
              <text :class="form.lostDate ? '' : 'publish__placeholder-text'">
                {{ form.lostDate || '丢失日期' }}
              </text>
            </view>
          </picker>
        </view>

        <view class="publish__row">
          <input
            class="publish__input"
            v-model="form.location"
            placeholder="丢失地点"
            placeholder-class="publish__placeholder"
          />
          <input
            class="publish__input"
            v-model="form.contact"
            placeholder="联系方式"
            placeholder-class="publish__placeholder"
            type="number"
          />
        </view>

        <!-- 物品特征 -->
        <text class="publish__section-title publish__section-title--gap">物品特征</text>
        <textarea
          class="publish__textarea"
          v-model="form.description"
          placeholder="请描述物品特征"
          placeholder-class="publish__placeholder"
          :auto-height="false"
        />

        <!-- 上传图片 -->
        <view class="publish__upload-area">
          <view class="publish__upload-box" @click="onChooseImage">
            <image
              v-if="imagePreview"
              :src="imagePreview"
              class="publish__preview-img"
              mode="aspectFill"
            />
            <template v-else>
              <text class="publish__plus">+</text>
              <text class="publish__upload-text">上传图片</text>
            </template>
          </view>
          <view v-if="imagePreview" class="publish__upload-status">
            <view class="publish__check"><text>✓</text></view>
            <text class="publish__status-text">上传图片</text>
          </view>
          <view v-else class="publish__upload-status">
            <view class="publish__check"><text>✓</text></view>
            <text class="publish__status-text">上传图片</text>
          </view>
        </view>

        <!-- 发布按钮 -->
        <button class="publish__submit-btn" @click="onSubmit">立即发布</button>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'

const form = reactive({
  title: '',
  lostDate: '',
  location: '',
  contact: '',
  description: '',
})

const imagePreview = ref('')

function onDateChange(e: any) {
  form.lostDate = e.detail.value
}

function onChooseImage() {
  uni.chooseImage({
    count: 1,
    success: (res) => {
      imagePreview.value = res.tempFilePaths[0]
    },
  })
}

function onSubmit() {
  if (!form.title || !form.lostDate || !form.contact) {
    uni.showToast({ title: '请完善物品名称、丢失日期和联系方式', icon: 'none' })
    return
  }
  uni.showModal({
    title: '提示',
    content: '发布成功！',
    showCancel: false,
    success: () => uni.navigateBack(),
  })
}
</script>

<style lang="scss" scoped>
@import '@/uni.scss';

.publish {
  min-height: 100vh;
  background: linear-gradient(180deg, #f0f5ff 0%, #e6f0ff 100%);
  display: flex;
  flex-direction: column;

  &__nav {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 20rpx 32rpx 40rpx;
  }
  &__back {
    padding: 8rpx;
  }
  &__back-icon {
    font-size: $font-2xl;
    color: $color-text;
    font-weight: 500;
  }
  &__title {
    font-size: $font-2xl;
    font-weight: 600;
    color: #1f1f1f;
  }
  &__nav-right {
    display: flex;
    align-items: center;
    gap: 24rpx;
  }
  &__dot-btn {
    display: flex;
    flex-direction: column;
    gap: 8rpx;
    padding: 8rpx;
  }
  &__dot {
    width: 8rpx;
    height: 8rpx;
    background: $color-text;
    border-radius: 50%;
  }

  &__scroll {
    flex: 1;
    padding: 0 32rpx;
  }

  &__card {
    background: #fff;
    border-radius: 40rpx;
    padding: 48rpx 40rpx 180rpx;
    box-shadow: 0 4rpx 24rpx rgba(0, 0, 0, 0.04);
  }

  &__section-title {
    display: block;
    font-size: $font-lg;
    font-weight: 600;
    color: #1f1f1f;
    margin-bottom: 32rpx;
    &--gap { margin-top: 48rpx; }
  }

  &__row {
    display: flex;
    gap: 24rpx;
    margin-bottom: 24rpx;
  }

  &__input {
    flex: 1;
    height: 96rpx;
    background: #f5f7fa;
    border-radius: 24rpx;
    border: none;
    padding: 0 32rpx;
    font-size: $font-base;
    color: $color-text;
    min-width: 0;
  }
  &__date-picker {
    display: flex;
    align-items: center;
    height: 96rpx;
    background: #f5f7fa;
    border-radius: 24rpx;
    padding: 0 32rpx;
    flex: 1;
  }
  &__placeholder-text {
    font-size: $font-base;
    color: #999;
  }
  &__placeholder {
    color: #999;
  }

  &__textarea {
    width: 100%;
    min-height: 240rpx;
    background: #f5f7fa;
    border-radius: 24rpx;
    border: none;
    padding: 32rpx;
    font-size: $font-base;
    color: $color-text;
    line-height: 1.5;
    margin-bottom: 48rpx;
  }

  &__upload-area {
    display: flex;
    align-items: center;
    gap: 32rpx;
    margin-bottom: 64rpx;
  }
  &__upload-box {
    width: 240rpx;
    height: 240rpx;
    border: 2rpx dashed #ccc;
    border-radius: 24rpx;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 16rpx;
    flex-shrink: 0;
    overflow: hidden;
  }
  &__preview-img {
    width: 100%;
    height: 100%;
  }
  &__plus {
    font-size: 64rpx;
    color: #999;
    font-weight: 300;
    line-height: 1;
  }
  &__upload-text {
    font-size: $font-sm;
    color: #999;
  }
  &__upload-status {
    display: flex;
    align-items: center;
    gap: 16rpx;
    background: #fff;
    padding: 16rpx 32rpx;
    border-radius: 40rpx;
    box-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.06);
  }
  &__check {
    width: 40rpx;
    height: 40rpx;
    background: #2385ff;
    border-radius: 50%;
    color: #fff;
    font-size: $font-sm;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  &__status-text {
    font-size: $font-base;
    color: #2385ff;
    font-weight: 500;
  }

  &__submit-btn {
    width: 100%;
    height: 104rpx;
    background: #2385ff;
    border-radius: 52rpx;
    border: none;
    font-size: $font-lg;
    font-weight: 600;
    color: #fff;
    display: flex;
    align-items: center;
    justify-content: center;
  }
}
</style>
