# yolov5-docker
A simple python docker application wrapping the Yolov5 AI

## Building

``` shell

docker run --privileged --rm tonistiigi/binfmt --install all

docker buildx create --use

docker buildx build --platform linux/amd64 -t thebigpotatoe/yolov5 . 
docker buildx build --platform linux/arm64 -t thebigpotatoe/yolov5 . 
docker buildx build --platform linux/arm/v7 -t thebigpotatoe/yolov5 . 
docker buildx build --platform linux/amd64,linux/arm/v7,linux/arm64 -t thebigpotatoe/yolov5 . 

```

## Publishing

``` shell

docker push thebigpotatoe/yolov5:latest

```

## Running 

```
# For testing
docker run \
    -it \
    --rm \
    -v /path/to/dir/input:/app/input \
    -v /path/to/dir/output:/app/output \
    thebigpotatoe/yolov5

# For production
docker run \
    -d \
    --restart=unless-stopped \
    -v /path/to/dir/input:/app/input \
    -v /path/to/dir/output:/app/output \
    -e app_input_dir=./input \
    -e app_output_dir=./output \
    -e app_input_dir=./input \
    -e app_loop_sleep=1 \
    -e model_dir_or_repo=ultralytics/yolov5 \
    -e model_name=yolov5s \
    thebigpotatoe/yolov5

```