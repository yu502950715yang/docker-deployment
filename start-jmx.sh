#!/bin/bash

# cd到应用目录（根据实际目录修改）
cd /home/business

# 设置Nacos相关的环境变量（根据实际情况修改）
export NACOS_SERVERADDR=10.0.0.240
export NACOS_PORT=8848
export NACOS_NAMESPACE_ID=prod
export NACOS_USERNAME=nacos
export NACOS_PASSWORD=Jxzn@2023._!
export SPRING_PROFILES_ACTIVE=prod

# JMX Exporter配置（根据实际文件修改）
export JMX_AGENT_PATH="/home/monitoring/jmx_prometheus/jmx_prometheus_javaagent-1.5.0.jar"
export JMX_CONFIG_PATH="/home/monitoring/jmx_prometheus/jmx_config.yml"  # 确保存在此配置文件
export JMX_PORT_OFFSET=10000  # JMX端口偏移量，避免与服务端口冲突

# 定义服务列表（服务名:服务端口）
declare -A services=(
    ["chenrise-app"]="5058"
    ["chenrise-auth"]="9200"
    ["chenrise-device"]="8888"
    ["chenrise-file"]="9300"
    ["chenrise-gateway"]="8080"
    ["chenrise-job"]="9202"
    ["chenrise-jufe"]="9204"
    ["chenrise-miniapp"]="9205"
    ["chenrise-patrol"]="9408"
    ["chenrise-system"]="9201"
    ["chenrise-camera"]="9999"
)

declare -r start_order="start"
declare -r stop_order="stop"

# 检查JMX Exporter文件是否存在（仅启动时需要）
check_jmx_files() {
    if [ ! -f "$JMX_AGENT_PATH" ]; then
        echo "Error: JMX Exporter agent not found at $JMX_AGENT_PATH"
        exit 1
    fi

    if [ ! -f "$JMX_CONFIG_PATH" ]; then
        echo "Error: JMX Exporter config not found at $JMX_CONFIG_PATH"
        exit 1
    fi
}

# 启动单个服务的函数
start_service() {
    local service_name=$1
    local port=$2
    
    # 计算JMX端口（服务端口+偏移量）
    local jmx_port=$((port + JMX_PORT_OFFSET))
    
    # 服务相关路径
    local service_path="$service_name.jar"
    local log_file="$service_name.log"
    
    # 杀死已存在的进程
    stop_service "$service_name"
    
    # 启动服务（包含JMX Exporter配置）
    echo "Starting $service_name: "
    echo "  Service port: $port"
    echo "  JMX Exporter port: $jmx_port"
    nohup java \
        -Xms8g -Xmx16g \
        -javaagent:"$JMX_AGENT_PATH"="$jmx_port:$JMX_CONFIG_PATH" \
        -jar "$service_path" \
        --server.port="$port" \
        > "$log_file" 2>&1 &
}

# 停止单个服务的函数
stop_service() {
    local service_name=$1
    
    # 查找并杀死已存在的进程
    pid=$(ps -ef | grep "$service_name.jar" | grep -v grep | awk '{print $2}')
    if [ -n "$pid" ]; then
        echo "Killing $service_name process (pid=$pid)"
        kill -9 "$pid"
    else
        echo "$service_name is not running"
    fi
}

# 处理命令参数
if [ $# -eq 1 ]; then
    sh_type=$1
    if [ "$sh_type" = "$start_order" ]; then
        # 启动所有服务
        check_jmx_files
        for service_name in "${!services[@]}"; do
            start_service "$service_name" "${services[$service_name]}"
        done
    elif [ "$sh_type" = "$stop_order" ]; then
        # 停止所有服务
        for service_name in "${!services[@]}"; do
            stop_service "$service_name"
        done
    else
        echo "Invalid command. Use 'start' or 'stop'."
    fi
elif [ $# -eq 2 ]; then
    sh_type=$1
    service_name=$2
    if [ "$sh_type" = "$start_order" ] && [ -n "${services[$service_name]}" ]; then
        # 启动指定服务
        check_jmx_files
        start_service "$service_name" "${services[$service_name]}"
    elif [ "$sh_type" = "$stop_order" ] && [ -n "${services[$service_name]}" ]; then
        # 停止指定服务
        stop_service "$service_name"
    else
        echo "Invalid command or service name. Usage:"
        echo "  start all services: $0 start"
        echo "  start specific service: $0 start <service_name>"
        echo "  stop all services: $0 stop"
        echo "  stop specific service: $0 stop <service_name>"
    fi
else
    echo "Commands:"
    echo "  start all services: $0 start"
    echo "  start specific service: $0 start <service_name>"
    echo "  stop all services: $0 stop"
    echo "  stop specific service: $0 stop <service_name>"
fi