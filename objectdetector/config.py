from pathlib import Path
from typing import List, Optional

from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing_extensions import Annotated
from visionlib.pipeline.settings import LogLevel, YamlConfigSettingsSource


class ModelConfig(BaseModel):
    weights_path: Path
    auto_download: bool = False
    device: str = 'cpu'
    confidence_threshold: float = 0.25
    iou_threshold: float = 0.45
    fp16: bool = False
    nms_agnostic: bool = False
    inference_size: tuple[int, int] = (640, 640)
    classes: Optional[List[int]] = None


class InputBackpressureConfig(BaseModel):
    # Whether to join the shared consumer group on the input streams, which lets the upstream stage
    # sense our lag and throttle itself
    enabled: bool = False


class OutputBackpressureConfig(BaseModel):
    # Whether to throttle publishing when the downstream stage cannot keep up
    enabled: bool = False
    # Consumer group lag (in messages) above which publishing is throttled; None -> visionlib default
    threshold: Optional[Annotated[int, Field(ge=1)]] = None
    # Seconds without any live consumer after which publishing resumes (and drops again); None -> block forever
    fail_open_timeout: Optional[Annotated[float, Field(ge=0)]] = 2.0


class RedisConfig(BaseModel):
    host: str = 'localhost'
    port: Annotated[int, Field(ge=1, le=65536)] = 6379
    stream_ids: Annotated[List[str], Field(min_length=1)]
    input_stream_prefix: str = 'videosource'
    output_stream_prefix: str = 'objectdetector'
    input_backpressure: InputBackpressureConfig = InputBackpressureConfig()
    output_backpressure: OutputBackpressureConfig = OutputBackpressureConfig()


class ObjectDetectorConfig(BaseSettings):
    log_level: LogLevel = LogLevel.WARNING
    model: ModelConfig
    max_batch_size: Annotated[int, Field(ge=1)] = 1
    max_batch_interval: Annotated[float, Field(ge=0)] = 0
    drop_edge_detections: bool = False
    redis: RedisConfig
    prometheus_port: Annotated[int, Field(gt=1024, le=65536)] = 8000

    model_config = SettingsConfigDict(env_nested_delimiter='__')

    @classmethod
    def settings_customise_sources(cls, settings_cls, init_settings, env_settings, dotenv_settings, file_secret_settings):
        return (init_settings, env_settings, YamlConfigSettingsSource(settings_cls), file_secret_settings)