import { request } from './request'

export interface LoginResult {
  access_token: string
  refresh_token: string
  is_new_user: boolean
}

export interface QuestionnairePayload {
  identity: string
  city: string
  interests: number[]
  purposes: number[]
  age_range: string
  personality?: string | null
  life_goal?: string | null
}

export interface EmailRegisterPayload {
  username: string
  email: string
  password: string
}

// 邮箱密码注册
export function emailRegister(payload: EmailRegisterPayload): Promise<LoginResult> {
  return request({ url: '/api/v1/auth/register', method: 'POST', data: payload })
}

// 邮箱密码登录
export function emailLogin(email: string, password: string): Promise<LoginResult> {
  return request({ url: '/api/v1/auth/login', method: 'POST', data: { email, password } })
}

// 微信一键登录（小程序主要登录方式）
export function wechatLogin(code: string): Promise<LoginResult> {
  return request({ url: '/api/v1/auth/wechat/login', method: 'POST', data: { code } })
}

// 手机号+验证码登录
export function sendSmsCode(phone: string): Promise<void> {
  return request({ url: '/api/v1/auth/sms/send', method: 'POST', data: { phone } })
}

export function verifySmsCode(phone: string, code: string): Promise<LoginResult> {
  return request({ url: '/api/v1/auth/sms/verify', method: 'POST', data: { phone, code } })
}

export function refreshToken(refresh_token: string): Promise<LoginResult> {
  return request({ url: '/api/v1/auth/refresh', method: 'POST', data: { refresh_token } })
}

export function logout(): Promise<void> {
  return request({ url: '/api/v1/auth/logout', method: 'POST' })
}

export function submitQuestionnaire(payload: QuestionnairePayload): Promise<void> {
  return request({ url: '/api/v1/users/me/questionnaire', method: 'POST', data: payload })
}
