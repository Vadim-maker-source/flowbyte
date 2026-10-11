from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "FLOWBYTE API"
    environment: str = "development"
    database_url: str = "sqlite+aiosqlite:///./flowbyte.db"
    gigachat_auth_key: str | None = None
    gigachat_scope: str = "GIGACHAT_API_PERS"
    gigachat_model: str = "GigaChat-2-Pro"
    gigachat_base_url: str = "https://api.giga.chat/v1"
    gigachat_oauth_url: str = "https://ngw.devices.sberbank.ru:9443/api/v2/oauth"
    # Optional path to a trusted CA bundle, if the system does not trust GigaChat's CA.
    gigachat_ca_bundle: str | None = None
    assistant_timeout_seconds: float = 45.0

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
