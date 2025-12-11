"""
Flask 主应用
提供查询语句生成API接口
"""

import os
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from query_generator import generate_all_queries

# 加载环境变量
load_dotenv()

app = Flask(__name__)

# 配置CORS
cors_origins = os.getenv('CORS_ORIGINS', '*')
if cors_origins == '*':
    CORS(app)
else:
    CORS(app, origins=cors_origins.split(','))

# 配置日志
log_level = os.getenv('LOG_LEVEL', 'INFO').upper()
logging.basicConfig(
    level=getattr(logging, log_level, logging.INFO),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),  # 输出到标准输出（Docker日志）
    ]
)
logger = logging.getLogger(__name__)

# 应用启动时间
app_start_time = datetime.now()


@app.route('/api/generate', methods=['POST'])
def generate_queries():
    """
    生成查询语句接口
    
    请求体:
    {
        "goodsId": "807708509179",
        "skuId": "1780376972946",
        "simGoodsId": "983723685861",
        "simSkuId": "5943842676368"
    }
    
    返回:
    {
        "mysql": "...",
        "es": "...",
        "api": "...",
        "log1": "...",
        "log2": "..."
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "请求体不能为空"}), 400
        
        # 获取参数，如果为空则使用空字符串
        goods_id = data.get('goodsId', '') or ''
        sku_id = data.get('skuId', '') or ''
        sim_goods_id = data.get('simGoodsId', '') or ''
        sim_sku_id = data.get('simSkuId', '') or ''
        platform_name = data.get('platformName', '') or ''
        
        # 生成所有查询语句
        queries = generate_all_queries(goods_id, sku_id, sim_goods_id, sim_sku_id, platform_name)
        
        logger.info(f"成功生成查询语句: goodsId={goods_id}, skuId={sku_id}")
        return jsonify(queries), 200
    
    except Exception as e:
        logger.error(f"生成查询语句失败: {str(e)}", exc_info=True)
        # 生产环境不暴露详细错误信息
        is_debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
        error_message = str(e) if is_debug else "服务器内部错误，请稍后重试"
        return jsonify({"error": error_message}), 500


@app.route('/api/health', methods=['GET'])
def health_check():
    """健康检查接口"""
    uptime = datetime.now() - app_start_time
    return jsonify({
        "status": "ok",
        "timestamp": datetime.now().isoformat(),
        "uptime_seconds": int(uptime.total_seconds()),
        "version": os.getenv('APP_VERSION', '1.0.0')
    }), 200


if __name__ == '__main__':
    # 从环境变量读取配置
    host = os.getenv('FLASK_HOST', '0.0.0.0')
    port = int(os.getenv('FLASK_PORT', '5000'))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    
    logger.info(f"启动Flask应用: host={host}, port={port}, debug={debug}")
    app.run(host=host, port=port, debug=debug)

