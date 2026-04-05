//! 对象存储服务封装
//!
//! # 功能
//! - 兼容 MinIO（开发）和阿里云 OSS（生产），通过环境变量切换
//! - 上传文件，返回公开访问 URL

use aws_sdk_s3::{Client, Config};
use aws_sdk_s3::config::{BehaviorVersion, Credentials, Region};
use chrono::Utc;
use uuid::Uuid;

use crate::{config::AppConfig, error::{AppError, AppResult}};

pub struct StorageService {
    client: Client,
    public_base_url: String,
}

impl StorageService {
    pub async fn from_config(config: &AppConfig) -> Self {
        let creds = Credentials::new(
            &config.storage_access_key,
            &config.storage_secret_key,
            None,
            None,
            "playmate",
        );

        let s3_config = Config::builder()
            .endpoint_url(&config.storage_endpoint)
            .credentials_provider(creds)
            .region(Region::new(config.storage_region.clone()))
            .force_path_style(true)
            .behavior_version(BehaviorVersion::latest())
            .build();

        Self {
            client: Client::from_conf(s3_config),
            public_base_url: config.storage_public_endpoint.clone(),
        }
    }

    /// 上传文件，返回公开访问 URL（格式：`{public_base_url}/{bucket}/{key}`）
    pub async fn upload(
        &self,
        bucket: &str,
        data: Vec<u8>,
        content_type: &str,
    ) -> AppResult<String> {
        let ext = mime_to_ext(content_type);
        let key = format!(
            "{}/{}.{}",
            Utc::now().format("%Y/%m/%d"),
            Uuid::new_v4(),
            ext,
        );

        self.client
            .put_object()
            .bucket(bucket)
            .key(&key)
            .body(data.into())
            .content_type(content_type)
            .send()
            .await
            .map_err(|e| AppError::Internal(anyhow::anyhow!("上传失败: {}", e)))?;

        Ok(format!("{}/{}/{}", self.public_base_url, bucket, key))
    }
}

fn mime_to_ext(mime: &str) -> &str {
    match mime {
        "image/jpeg" => "jpg",
        "image/png" => "png",
        "image/webp" => "webp",
        "audio/m4a" => "m4a",
        "audio/mpeg" => "mp3",
        "video/mp4" => "mp4",
        _ => "bin",
    }
}
