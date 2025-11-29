"""
查询语句生成器模块
提供MySQL、ES、API、Log等查询语句的生成功能
"""

import json


def generate_mysql_query(goods_id, sku_id, sim_goods_id, sim_sku_id):
    """
    生成MySQL查询语句
    
    Args:
        goods_id: origin_goods_id
        sku_id: origin_sku_id
        sim_goods_id: similar_goods_id
        sim_sku_id: similar_sku_id
    
    Returns:
        MySQL查询语句字符串
    """
    query = f"""SELECT * FROM auto_compare_report 
WHERE origin_goods_id = '{goods_id}' 
AND origin_sku_id = '{sku_id}' 
AND similar_goods_id = '{sim_goods_id}' 
AND similar_sku_id = '{sim_sku_id}' 
LIMIT 50;"""
    return query


def generate_es_query(goods_id, sku_id, sim_goods_id, sim_sku_id):
    """
    生成Elasticsearch查询JSON
    
    Args:
        goods_id: origin_goods_id
        sku_id: origin_sku_id
        sim_goods_id: similar_goods_id
        sim_sku_id: similar_sku_id
    
    Returns:
        格式化的JSON字符串
    """
    query = {
        "query": {
            "bool": {
                "filter": [
                    {"term": {"origin_goods_id": goods_id}},
                    {"term": {"origin_sku_id": sku_id}},
                    {"term": {"similar_goods_id": sim_goods_id}},
                    {"term": {"similar_sku_id": sim_sku_id}}
                ]
            }
        },
        "sort": [
            {
                "report_time": {
                    "order": "desc"
                }
            }
        ]
    }
    return json.dumps(query, indent=4, ensure_ascii=False)


def generate_api_request(goods_id, sku_id, sim_goods_id, sim_sku_id):
    """
    生成API请求JSON
    
    Args:
        goods_id: goodsId
        sku_id: skuId
        sim_goods_id: simGoodsId
        sim_sku_id: simSkuId
    
    Returns:
        格式化的JSON字符串
    """
    # 将字符串转换为整数（如果可能）
    try:
        goods_id_int = int(goods_id) if goods_id else 0
        sku_id_int = int(sku_id) if sku_id else 0
        sim_goods_id_int = int(sim_goods_id) if sim_goods_id else 0
        sim_sku_id_int = int(sim_sku_id) if sim_sku_id else 0
    except ValueError:
        goods_id_int = 0
        sku_id_int = 0
        sim_goods_id_int = 0
        sim_sku_id_int = 0
    
    request_data = [
        {
            "goodsId": goods_id_int,
            "skuId": sku_id_int,
            "simGoodsId": sim_goods_id_int,
            "simSkuId": sim_sku_id_int,
            "platformName": "JD",
            "sceneCode": 2
        }
    ]
    return json.dumps(request_data, indent=2, ensure_ascii=False)


def generate_log_query(goods_id, sku_id, sim_goods_id, sim_sku_id, query_type=1):
    """
    生成Log日志查询语句
    
    Args:
        goods_id: goodsId
        sku_id: skuId
        sim_goods_id: simGoodsId
        sim_sku_id: simSkuId
        query_type: 查询类型，1为置灰拦截查询，2为接口查询核心bool值构造语句
    
    Returns:
        Log查询语句字符串
    """
    if query_type == 1:
        # 置灰拦截查询
        return f'"hasErrorRecord: found error pairDTO" and "{goods_id}" and "{sku_id}" and "{sim_goods_id}" and "{sim_sku_id}"'
    else:
        # 接口查询核心bool值构造语句
        return f'"buildQueryCore result:" and "{goods_id}" and "{sku_id}" and "{sim_goods_id}" and "{sim_sku_id}"'


def generate_all_queries(goods_id, sku_id, sim_goods_id, sim_sku_id):
    """
    生成所有类型的查询语句
    
    Args:
        goods_id: goodsId
        sku_id: skuId
        sim_goods_id: simGoodsId
        sim_sku_id: simSkuId
    
    Returns:
        包含所有查询语句的字典
    """
    return {
        "mysql": generate_mysql_query(goods_id, sku_id, sim_goods_id, sim_sku_id),
        "es": generate_es_query(goods_id, sku_id, sim_goods_id, sim_sku_id),
        "api": generate_api_request(goods_id, sku_id, sim_goods_id, sim_sku_id),
        "log1": generate_log_query(goods_id, sku_id, sim_goods_id, sim_sku_id, 1),
        "log2": generate_log_query(goods_id, sku_id, sim_goods_id, sim_sku_id, 2)
    }

