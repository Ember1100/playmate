const BASE_URL = 'http://8.138.190.48:8080'

export interface ApiResponse<T> {
  success: boolean
  code: string
  message: string
  data: T | null
}

export interface PageResponse<T> {
  items: T[]
  total: number
  page: number
  limit: number
  has_more: boolean
}

export function request<T>(options: {
  url: string
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  data?: object
}): Promise<T> {
  const token = uni.getStorageSync('access_token')
  return new Promise((resolve, reject) => {
    uni.request({
      url: BASE_URL + options.url,
      method: options.method ?? 'GET',
      data: options.data,
      header: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      success: (res) => {
        const body = res.data as ApiResponse<T>
        if (body.success) {
          resolve(body.data as T)
        } else {
          if (res.statusCode === 401) {
            uni.removeStorageSync('access_token')
            uni.navigateTo({ url: '/pages/auth/login' })
          }
          reject(new Error(body.message))
        }
      },
      fail: (err) => reject(new Error(err.errMsg)),
    })
  })
}

export function upload(options: {
  url: string
  filePath: string
  name?: string
  formData?: object
}): Promise<string> {
  const token = uni.getStorageSync('access_token')
  return new Promise((resolve, reject) => {
    uni.uploadFile({
      url: BASE_URL + options.url,
      filePath: options.filePath,
      name: options.name ?? 'file',
      formData: options.formData,
      header: { Authorization: `Bearer ${token}` },
      success: (res) => {
        const body = JSON.parse(res.data) as ApiResponse<string>
        if (body.success) resolve(body.data as string)
        else reject(new Error(body.message))
      },
      fail: (err) => reject(new Error(err.errMsg)),
    })
  })
}
