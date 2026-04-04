//! 应用配置加载与校验

use serde::Deserialize;

#[derive(Deserialize, Clone, Debug)]
pub struct AppConfig {
    pub database_url: String,
    pub redis_url: String,
    pub jwt_secret: String,
    pub jwt_refresh_secret: String,

    #[serde(default = "default_host")]
    pub server_host: String,
    #[serde(default = "default_port")]
    pub server_port: u16,

    #[serde(default)]
    pub wechat_app_id: String,
    #[serde(default)]
    pub wechat_app_secret: String,

    #[serde(default)]
    pub aliyun_sms_access_key: String,
    #[serde(default)]
    pub aliyun_sms_secret: String,
    #[serde(default = "default_sms_sign")]
    pub aliyun_sms_sign_name: String,
    #[serde(default)]
    pub aliyun_sms_template_code: String,
}

fn default_host() -> String { "0.0.0.0".to_string() }
fn default_port() -> u16 { 8080 }
fn default_sms_sign() -> String { "玩伴".to_string() }

impl AppConfig {
    pub fn from_env() -> anyhow::Result<Self> {
        let cfg = envy::from_env::<AppConfig>()
            .map_err(|e| anyhow::anyhow!("配置读取失败: {}", e))?;
        cfg.validate()?;
        Ok(cfg)
    }

    fn validate(&self) -> anyhow::Result<()> {
        if self.database_url.is_empty() {
            anyhow::bail!("DATABASE_URL 未设置");
        }
        if self.redis_url.is_empty() {
            anyhow::bail!("REDIS_URL 未设置");
        }
        if self.jwt_secret.len() < 32 {
            anyhow::bail!("JWT_SECRET 长度不足 32 位（当前 {} 位）", self.jwt_secret.len());
        }
        if self.jwt_refresh_secret.len() < 32 {
            anyhow::bail!(
                "JWT_REFRESH_SECRET 长度不足 32 位（当前 {} 位）",
                self.jwt_refresh_secret.len()
            );
        }
        Ok(())
    }
}
