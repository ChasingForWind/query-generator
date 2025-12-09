<template>
  <div class="query-generator">
    <div class="container">
      <h1 class="title">报错pair查询语句生成器</h1>

      <div class="tabs">
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'generator' }"
          @click="activeTab = 'generator'"
        >
          查询生成
        </button>
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'esParser' }"
          @click="activeTab = 'esParser'"
        >
          报错ES数据反解析
        </button>
      </div>

      <div v-if="activeTab === 'generator'">
        <!-- 文本解析输入区域 -->
        <div class="text-parser-section">
          <div class="input-group full-width">
            <label for="textInput">粘贴文本自动解析</label>
            <textarea
              id="textInput"
              v-model="textInput"
              class="text-input"
              placeholder="请粘贴包含商品信息的文本，系统将自动解析并填充以下字段..."
              rows="6"
              @input="handleTextInput"
              @paste="handleTextInput"
            ></textarea>
          </div>
        </div>
        
        <!-- 输入区域 -->
        <div class="input-section">
          <div class="input-group">
            <label for="goodsId">Goods ID</label>
            <input
              id="goodsId"
              v-model="formData.goodsId"
              type="text"
              placeholder="请输入 goodsId"
              @input="handleInputChange"
            />
          </div>
          
          <div class="input-group">
            <label for="skuId">SKU ID</label>
            <input
              id="skuId"
              v-model="formData.skuId"
              type="text"
              placeholder="请输入 skuId"
              @input="handleInputChange"
            />
          </div>
          
          <div class="input-group">
            <label for="simGoodsId">Sim Goods ID</label>
            <input
              id="simGoodsId"
              v-model="formData.simGoodsId"
              type="text"
              placeholder="请输入 simGoodsId"
              @input="handleInputChange"
            />
          </div>
          
          <div class="input-group">
            <label for="simSkuId">Sim SKU ID</label>
            <input
              id="simSkuId"
              v-model="formData.simSkuId"
              type="text"
              placeholder="请输入 simSkuId"
              @input="handleInputChange"
            />
          </div>
        </div>

        <!-- 查询结果区域 -->
        <div class="results-section">
          <!-- MySQL 查询 -->
          <div class="query-card">
            <div class="query-header">
              <h2>MySQL 查询</h2>
              <div class="action-buttons">
                <button @click="copyToClipboard(queries.mysql, 'mysql')" class="copy-btn">
                  {{ copyStatus.mysql ? '已复制!' : '复制' }}
                </button>
                <button @click="copyAndJump(queries.mysql, 'mysql')" class="jump-btn" :disabled="!queries.mysql">
                  跳转
                </button>
              </div>
            </div>
            <pre class="query-content"><code>{{ queries.mysql || '等待输入...' }}</code></pre>
          </div>

          <!-- ES 查询 -->
          <div class="query-card">
            <div class="query-header">
              <h2>Elasticsearch 查询</h2>
              <div class="action-buttons">
                <button @click="copyToClipboard(queries.es, 'es')" class="copy-btn">
                  {{ copyStatus.es ? '已复制!' : '复制' }}
                </button>
                <button @click="copyAndJump(queries.es, 'es')" class="jump-btn" :disabled="!queries.es">
                  跳转
                </button>
              </div>
            </div>
            <pre class="query-content"><code>{{ queries.es || '等待输入...' }}</code></pre>
          </div>

          <!-- API 请求 -->
          <div class="query-card">
            <div class="query-header">
              <h2>API 请求</h2>
              <div class="action-buttons">
                <button @click="copyToClipboard(queries.api, 'api')" class="copy-btn">
                  {{ copyStatus.api ? '已复制!' : '复制' }}
                </button>
                <button @click="copyAndJump(queries.api, 'api')" class="jump-btn" :disabled="!queries.api">
                  跳转
                </button>
              </div>
            </div>
            <pre class="query-content"><code>{{ queries.api || '等待输入...' }}</code></pre>
          </div>

          <!-- Log 查询 1 -->
          <div class="query-card">
            <div class="query-header">
              <h2>Log 查询 - 置灰拦截</h2>
              <div class="action-buttons">
                <button @click="copyToClipboard(queries.log1, 'log1')" class="copy-btn">
                  {{ copyStatus.log1 ? '已复制!' : '复制' }}
                </button>
                <button @click="copyAndJump(queries.log1, 'log1')" class="jump-btn" :disabled="!queries.log1">
                  跳转
                </button>
              </div>
            </div>
            <pre class="query-content"><code>{{ queries.log1 || '等待输入...' }}</code></pre>
          </div>

          <!-- Log 查询 2 -->
          <div class="query-card">
            <div class="query-header">
              <h2>Log 查询 - 下游接口查询ES bool值构造</h2>
              <div class="action-buttons">
                <button @click="copyToClipboard(queries.log2, 'log2')" class="copy-btn">
                  {{ copyStatus.log2 ? '已复制!' : '复制' }}
                </button>
                <button @click="copyAndJump(queries.log2, 'log2')" class="jump-btn" :disabled="!queries.log2">
                  跳转
                </button>
              </div>
            </div>
            <pre class="query-content"><code>{{ queries.log2 || '等待输入...' }}</code></pre>
          </div>

          <!-- MySQL 黑名单 goods 维度 -->
          <div class="query-card">
            <div class="query-header">
              <h2>MySQL 黑名单 - goods 维度</h2>
              <div class="action-buttons">
                <button @click="copyToClipboard(queries.mysqlBlackGoods, 'mysqlBlackGoods')" class="copy-btn">
                  {{ copyStatus.mysqlBlackGoods ? '已复制!' : '复制' }}
                </button>
                <button @click="copyAndJump(queries.mysqlBlackGoods, 'mysqlBlackGoods')" class="jump-btn" :disabled="!queries.mysqlBlackGoods">
                  跳转
                </button>
              </div>
            </div>
            <pre class="query-content"><code>{{ queries.mysqlBlackGoods || '等待输入...' }}</code></pre>
          </div>

          <!-- MySQL 黑名单 pair 维度 -->
          <div class="query-card">
            <div class="query-header">
              <h2>MySQL 黑名单 - pair 维度</h2>
              <div class="action-buttons">
                <button @click="copyToClipboard(queries.mysqlBlackPair, 'mysqlBlackPair')" class="copy-btn">
                  {{ copyStatus.mysqlBlackPair ? '已复制!' : '复制' }}
                </button>
                <button @click="copyAndJump(queries.mysqlBlackPair, 'mysqlBlackPair')" class="jump-btn" :disabled="!queries.mysqlBlackPair">
                  跳转
                </button>
              </div>
            </div>
            <pre class="query-content"><code>{{ queries.mysqlBlackPair || '等待输入...' }}</code></pre>
          </div>

          <!-- 入库日志查询 -->
          <div class="query-card">
            <div class="query-header">
              <h2>入库日志查询</h2>
              <div class="action-buttons">
                <button @click="copyToClipboard(queries.log3, 'log3')" class="copy-btn">
                  {{ copyStatus.log3 ? '已复制!' : '复制' }}
                </button>
                <button @click="copyAndJump(queries.log3, 'log3')" class="jump-btn" :disabled="!queries.log3">
                  跳转
                </button>
              </div>
            </div>
            <pre class="query-content"><code>{{ queries.log3 || '等待输入...' }}</code></pre>
          </div>
        </div>
      </div>

      <div v-else class="es-parser-section">
        <div class="text-parser-section">
          <div class="input-group full-width">
            <label for="esParserInput">粘贴 ES 返回 JSON</label>
            <textarea
              id="esParserInput"
              v-model="esParserInput"
              class="text-input"
              placeholder="粘贴 Kibana/ES 返回的 JSON（包含 hits.hits ）"
              rows="12"
            ></textarea>
          </div>
        </div>

        <div class="parser-actions">
          <button class="copy-btn" @click="parseEsData">解析</button>
          <button class="jump-btn" @click="clearEsParser">清空</button>
        </div>

        <div class="parser-result">
          <div v-if="esParserError" class="error-text">{{ esParserError }}</div>
          <div v-else-if="!esParserItems.length" class="placeholder-text">等待解析数据...</div>
          <div v-else class="table-wrapper">
            <table class="parser-table">
              <thead>
                <tr>
                  <th>左 goodsId</th>
                  <th>左 skuId</th>
                  <th>套餐Id</th>
                  <th>右 goodsId</th>
                  <th>右 skuId</th>
                  <th>平台</th>
                  <th>报错人</th>
                  <th>报错时间</th>
                  <th>审核时间</th>
                  <th>当前状态</th>
                  <th>审核状态</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(row, index) in esParserItems" :key="index">
                  <td>{{ row.leftGoodsId || '-' }}</td>
                  <td>{{ row.leftSkuId || '-' }}</td>
                  <td>{{ row.productId || '-' }}</td>
                  <td>{{ row.rightGoodsId || '-' }}</td>
                  <td>{{ row.rightSkuId || '-' }}</td>
                  <td>{{ row.platform || '-' }}</td>
                  <td>{{ row.reporter || '-' }}</td>
                  <td>{{ row.reportTime || '-' }}</td>
                  <td>{{ row.verifyTime || '-' }}</td>
                  <td>{{ row.status || '-' }}</td>
                  <td>{{ row.verifyResult || '-' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'QueryGenerator',
  data() {
    return {
      activeTab: 'generator',
      textInput: '',
      formData: {
        goodsId: '',
        skuId: '',
        simGoodsId: '',
        simSkuId: ''
      },
      queries: {
        mysql: '',
        es: '',
        api: '',
        log1: '',
        log2: '',
        mysqlBlackGoods: '',
        mysqlBlackPair: '',
        log3: ''
      },
      copyStatus: {
        mysql: false,
        es: false,
        api: false,
        log1: false,
        log2: false,
        mysqlBlackGoods: false,
        mysqlBlackPair: false,
        log3: false
      },
      esParserInput: '',
      esParserItems: [],
      esParserError: '',
      debounceTimer: null,
      textParseTimer: null,
      // 跳转URL配置
      // 配置说明：
      // 1. 如果配置了URL，点击"跳转"按钮会先复制内容，然后在新标签页打开配置的URL
      // 2. 查询内容会作为URL参数传递（参数名：query）
      // 3. 对于log1和log2，查询内容会合并到Kibana的查询参数中
      // 4. 可以通过 window.JUMP_URLS 全局变量覆盖这些配置（在index.html中设置）
      jumpUrls: (() => {
        // 优先使用全局配置（如果存在）
        if (typeof window !== 'undefined' && window.JUMP_URLS) {
          return {
            mysql: window.JUMP_URLS.mysql || '',
            es: window.JUMP_URLS.es || '',
            api: window.JUMP_URLS.api || '',
            log1: window.JUMP_URLS.log1 || '',
            log2: window.JUMP_URLS.log2 || '',
            mysqlBlackGoods: window.JUMP_URLS.mysqlBlackGoods || '',
            mysqlBlackPair: window.JUMP_URLS.mysqlBlackPair || '',
            log3: window.JUMP_URLS.log3 || ''
          }
        }
        // 默认配置
        return {
          mysql: 'https://easydb.pdd.net/query2?cluster_name=172.20.135.180%3A3306&database_name=pdd_alioth&instance_type=single&table_name=auto_compare_report&type=MySQL',
          es: 'https://easydb.pdd.net/query2?cluster_name=pes-goods5-report-error-st5&table_name=ascend-error-pair-search-es&type=ES',
          api: 'https://dove.pdd.net/document/app/ascend-api/dubbo/api/com.pinduoduo.ascend.contract.dubbo.api.QueryService%23queryReportedPair(java.util.List%3Ccom.pinduoduo.ascend.contract.dubbo.model.request.ReportedPairStatusRequest%3E)?env=prod&hostGroup=def&search=queryReported&tab=1&version=30581678',
          log1: 'https://log.pdd.net/app/kibana#/discover?_g=()&_a=(columns:!(_source),index:pdd-ascend-api,interval:auto,query:(language:kuery,query:\'%22checkGreyPair%20request%20is%20:%20%22\'),sort:!(!(\'@timestamp\',desc)))',
          log2: 'https://log.pdd.net/app/kibana#/discover?_g=()&_a=(columns:!(_source),index:pdd-ascend-api,interval:auto,query:(language:kuery,query:\'%22buildQueryCore%20result:%22\'),sort:!(!(\'@timestamp\',desc)))',
          mysqlBlackGoods: 'https://easydb.pdd.net/query2?cluster_name=10.220.102.6%3A3326&database_name=ascend&instance_type=single&table_name=report_error_black_goods&type=MySQL',
          mysqlBlackPair: 'https://easydb.pdd.net/query2?cluster_name=10.220.102.6%3A3326&database_name=ascend&instance_type=single&table_name=report_error_black_pair&type=MySQL',
          log3: 'https://log.pdd.net/app/kibana#/discover?_g=()&_a=(columns:!(_source),index:pdd-ascend-api,interval:auto,query:(language:kuery,query:\'%22manualReport%20req:%22%20and%20%22%22%20and%20%22%22%20and%20%22%22%20and%20%22%22\'),sort:!(!(\'@timestamp\',desc)))'
        }
      })()
    }
  },
  methods: {
    getEmptyQueries() {
      return {
        mysql: '',
        es: '',
        api: '',
        log1: '',
        log2: '',
        mysqlBlackGoods: '',
        mysqlBlackPair: '',
        log3: ''
      }
    },
    
    handleTextInput() {
      // 防抖处理，避免频繁解析
      clearTimeout(this.textParseTimer)
      this.textParseTimer = setTimeout(() => {
        this.parseTextAndFill()
      }, 500)
    },
    
    parseTextAndFill() {
      if (!this.textInput || !this.textInput.trim()) {
        return
      }
      
      const text = this.textInput
      
      // 解析函数：提取字段值（支持中英文冒号，匹配到行尾或换行）
      const extractValue = (pattern, text) => {
        const match = text.match(pattern)
        if (match && match[1]) {
          // 去除前后空格和可能的换行符
          return match[1].trim().replace(/[\r\n]+/g, '')
        }
        return null
      }
      
      // 解析原商品goods_id
      const originalGoodsId = extractValue(/原商品\s*goods_id\s*[:：]\s*([^\r\n]+)/i, text)
      if (originalGoodsId) {
        this.formData.goodsId = originalGoodsId
      }
      
      // 解析原商品sku_id
      const originalSkuId = extractValue(/原商品\s*sku_id\s*[:：]\s*([^\r\n]+)/i, text)
      if (originalSkuId) {
        this.formData.skuId = originalSkuId
      }
      
      // 解析同款商品goods_id
      const simGoodsId = extractValue(/同款商品\s*goods_id\s*[:：]\s*([^\r\n]+)/i, text)
      if (simGoodsId) {
        this.formData.simGoodsId = simGoodsId
      }
      
      // 解析同款商品sku_id
      const simSkuId = extractValue(/同款商品\s*sku_id\s*[:：]\s*([^\r\n]+)/i, text)
      if (simSkuId) {
        this.formData.simSkuId = simSkuId
      }
      
      // 填充后触发查询生成
      this.handleInputChange()
    },
    
    handleInputChange() {
      // 防抖处理，避免频繁请求
      clearTimeout(this.debounceTimer)
      this.debounceTimer = setTimeout(() => {
        this.generateQueries()
      }, 300)
    },
    
    async generateQueries() {
      // 如果所有输入都为空，清空结果
      if (!this.formData.goodsId && !this.formData.skuId && 
          !this.formData.simGoodsId && !this.formData.simSkuId) {
        this.queries = this.getEmptyQueries()
        return
      }

      let newQueries = this.getEmptyQueries()

      try {
        const response = await axios.post('/api/generate', this.formData)
        newQueries = { ...newQueries, ...(response.data || {}) }
      } catch (error) {
        console.error('生成查询语句失败:', error)
        // 可以添加错误提示
      }

      newQueries.mysqlBlackGoods = this.buildMysqlBlackGoodsQuery()
      newQueries.mysqlBlackPair = this.buildMysqlBlackPairQuery()
      newQueries.log3 = this.buildLog3Query()

      this.queries = newQueries
    },
    
    async copyToClipboard(text, type) {
      if (!text) return
      
      try {
        await navigator.clipboard.writeText(text)
        // 设置复制状态
        this.copyStatus[type] = true
        setTimeout(() => {
          this.copyStatus[type] = false
        }, 2000)
      } catch (error) {
        console.error('复制失败:', error)
        // 降级方案：使用传统方法
        const textArea = document.createElement('textarea')
        textArea.value = text
        textArea.style.position = 'fixed'
        textArea.style.opacity = '0'
        document.body.appendChild(textArea)
        textArea.select()
        try {
          document.execCommand('copy')
          this.copyStatus[type] = true
          setTimeout(() => {
            this.copyStatus[type] = false
          }, 2000)
        } catch (err) {
          console.error('复制失败:', err)
        }
        document.body.removeChild(textArea)
      }
    },
    
    async copyAndJump(text, type) {
      if (!text) return
      
      // 先复制到剪贴板
      await this.copyToClipboard(text, type)
      
      // 获取配置的跳转URL
      const jumpUrl = this.jumpUrls[type]
      
      if (jumpUrl && jumpUrl.trim()) {
        // 如果配置了URL，则跳转
        try {
          let finalUrl = jumpUrl
          
          // 对于log类（Kibana），需要将查询内容合并到Kibana的query参数中
          if (['log1', 'log2', 'log3'].includes(type)) {
            // Kibana URL格式：query:(language:kuery,query:'...')
            // 生成的查询已经是完整的KQL查询语句，直接替换URL中的query参数
            
            // 提取query参数部分：query:(language:kuery,query:'...')
            // URL中query参数是编码后的，例如：query:(language:kuery,query:'%22checkGreyPair%20request%20is%20:%20%22')
            const queryMatch = jumpUrl.match(/query:\(language:kuery,query:'([^']+)'\)/)
            if (queryMatch) {
              // 将生成的查询内容进行URL编码
              // 生成的查询格式：'"hasErrorRecord: found error pairDTO" and "123" and "456"'
              const encodedQuery = encodeURIComponent(text)
              // 替换URL中的query参数（保持原有格式）
              finalUrl = jumpUrl.replace(/query:\(language:kuery,query:'([^']+)'\)/, `query:(language:kuery,query:'${encodedQuery}')`)
            } else {
              // 如果无法解析，尝试更宽松的匹配
              const encodedQuery = encodeURIComponent(text)
              // 尝试替换整个query部分
              finalUrl = jumpUrl.replace(/query:\(language:kuery,query:'[^']+'\)/, `query:(language:kuery,query:'${encodedQuery}')`)
            }
          } else {
            // 对于其他类型，将查询内容作为query参数添加
            const encodedQuery = encodeURIComponent(text)
            finalUrl = jumpUrl.includes('?') 
              ? `${jumpUrl}&query=${encodedQuery}` 
              : `${jumpUrl}?query=${encodedQuery}`
          }
          
          // 在新标签页打开
          window.open(finalUrl, '_blank')
        } catch (error) {
          console.error('跳转失败:', error)
          // 如果URL格式有问题，直接打开配置的URL
          window.open(jumpUrl, '_blank')
        }
      } else {
        // 如果没有配置URL，根据类型打开默认工具或提示
        this.openDefaultTool(type, text)
      }
    },
    
    openDefaultTool(type, text) {
      // 根据查询类型打开默认工具或提示用户
      const typeNames = {
        mysql: 'MySQL查询工具',
        mysqlBlackGoods: 'MySQL查询工具',
        mysqlBlackPair: 'MySQL查询工具',
        es: 'Elasticsearch Dev Tools（如Kibana）',
        api: 'API测试工具（如Postman）',
        log1: '日志查询系统（如Kibana Discover）',
        log2: '日志查询系统（如Kibana Discover）',
        log3: '日志查询系统（如Kibana Discover）'
      }
      
      const typeName = typeNames[type] || '对应工具'
      
      // 提示用户已复制，可以手动粘贴到工具中
      const message = `已复制到剪贴板！\n\n请打开 ${typeName}，然后粘贴查询内容。\n\n提示：您可以在代码中配置跳转URL，实现一键跳转。\n\n配置方法：\n1. 修改 frontend/src/components/QueryGenerator.vue 中的 jumpUrls 对象\n2. 或在 index.html 中设置 window.JUMP_URLS 全局变量`
      
      // 使用 confirm 让用户选择是否继续
      if (confirm(message + '\n\n是否现在打开新标签页以便手动粘贴？')) {
        // 打开空白新标签页，用户可以手动访问工具
        window.open('about:blank', '_blank')
      }
    },

    buildMysqlBlackGoodsQuery() {
      if (!this.formData.goodsId) return ''
      return "SELECT * FROM `report_error_black_goods` WHERE goods_id = '" + this.formData.goodsId + "' LIMIT 50;"
    },

    buildMysqlBlackPairQuery() {
      if (!this.formData.goodsId && !this.formData.simGoodsId) return ''
      const origin = this.formData.goodsId || ''
      const similar = this.formData.simGoodsId || ''
      return "SELECT * FROM `report_error_black_pair` WHERE origin_goods_id = '" + origin + "' AND similar_goods_id = '" + similar + "' LIMIT 50;"
    },

    buildLog3Query() {
      if (!this.formData.goodsId && !this.formData.skuId && !this.formData.simGoodsId && !this.formData.simSkuId) {
        return ''
      }
      const parts = [
        'manualReport req:',
        this.formData.goodsId || '',
        this.formData.skuId || '',
        this.formData.simGoodsId || '',
        this.formData.simSkuId || ''
      ]
      return parts.map(item => `"${item}"`).join(' and ')
    },

    parseEsData() {
      this.esParserError = ''
      this.esParserItems = []

      if (!this.esParserInput || !this.esParserInput.trim()) {
        this.esParserError = '请输入 ES 返回的 JSON 数据'
        return
      }

      try {
        const json = JSON.parse(this.esParserInput)
        const hits = json?.hits?.hits

        if (!Array.isArray(hits) || !hits.length) {
          this.esParserError = '未找到 hits.hits 数据'
          return
        }

        const rows = hits.map(hit => {
          const source = hit._source || {}
          return {
            leftGoodsId: source.origin_goods_id || '',
            leftSkuId: source.origin_sku_id || '',
            productId: source.product_id || '',
            rightGoodsId: source.similar_goods_id || '',
            rightSkuId: source.similar_sku_id || '',
            platform: source.similar_platform_str || '',
            reporter: source.reporter || '',
            reportTime: this.formatDate(source.report_time),
            verifyTime: this.formatDate(source.verify_time),
            status: this.mapStatus(source.status),
            verifyResult: this.mapVerifyResult(source.verify_result)
          }
        }).filter(item => item.leftGoodsId || item.rightGoodsId)

        if (!rows.length) {
          this.esParserError = '未解析到有效的 pair 数据'
          return
        }

        this.esParserItems = rows
      } catch (error) {
        this.esParserError = `解析失败：${error.message}`
      }
    },

    clearEsParser() {
      this.esParserInput = ''
      this.esParserItems = []
      this.esParserError = ''
    },

    formatDate(value) {
      if (!value && value !== 0) return ''
      const num = Number(value)
      if (!Number.isFinite(num)) return ''
      const millis = num > 1e12 ? num : num * 1000
      const date = new Date(millis)
      if (Number.isNaN(date.getTime())) return ''
      const y = date.getFullYear()
      const m = String(date.getMonth() + 1).padStart(2, '0')
      const d = String(date.getDate()).padStart(2, '0')
      const hh = String(date.getHours()).padStart(2, '0')
      const mm = String(date.getMinutes()).padStart(2, '0')
      const ss = String(date.getSeconds()).padStart(2, '0')
      return `${y}-${m}-${d} ${hh}:${mm}:${ss}`
    },

    mapStatus(status) {
      const map = {
        0: '不生效',
        1: '生效-剔除不比',
        2: '生效-不剔除，套餐重新比价',
        3: '生效-不剔除，历史比价场景，用新价格比价'
      }
      return map[status] || ''
    },

    mapVerifyResult(result) {
      const map = {
        0: '待审核',
        1: '审核通过',
        2: '审核不通过'
      }
      return map[result] || ''
    }
  }
}
</script>

<style scoped>
.query-generator {
  max-width: 1200px;
  margin: 0 auto;
}

.container {
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  padding: 40px;
}

.title {
  text-align: center;
  color: #333;
  margin-bottom: 40px;
  font-size: 32px;
  font-weight: 600;
}

.tabs {
  display: flex;
  gap: 12px;
  margin-bottom: 24px;
}

.tab-btn {
  flex: 1;
  padding: 12px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  background: #f8f9fa;
  cursor: pointer;
  font-size: 15px;
  font-weight: 600;
  color: #555;
  transition: all 0.2s;
}

.tab-btn.active {
  border-color: #667eea;
  background: #eef2ff;
  color: #3b3bb3;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
}

.text-parser-section {
  margin-bottom: 30px;
}

.text-parser-section .full-width {
  grid-column: 1 / -1;
}

.text-input {
  padding: 12px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 14px;
  font-family: inherit;
  line-height: 1.6;
  resize: vertical;
  transition: all 0.3s;
  width: 100%;
  box-sizing: border-box;
}

.text-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.input-section {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 40px;
}

.input-group {
  display: flex;
  flex-direction: column;
}

.input-group label {
  margin-bottom: 8px;
  color: #555;
  font-weight: 500;
  font-size: 14px;
}

.input-group input {
  padding: 12px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 14px;
  transition: all 0.3s;
}

.input-group input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.results-section {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.query-card {
  border: 1px solid #e0e0e0;
  border-radius: 12px;
  overflow: hidden;
  transition: all 0.3s;
}

.query-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.query-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  background: #f8f9fa;
  border-bottom: 1px solid #e0e0e0;
}

.query-header h2 {
  font-size: 18px;
  color: #333;
  font-weight: 600;
}

.action-buttons {
  display: flex;
  gap: 10px;
  align-items: center;
}

.copy-btn {
  padding: 8px 16px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.3s;
}

.copy-btn:hover {
  background: #5568d3;
  transform: translateY(-1px);
}

.copy-btn:active {
  transform: translateY(0);
}

.jump-btn {
  padding: 8px 16px;
  background: #48bb78;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.3s;
}

.jump-btn:hover:not(:disabled) {
  background: #38a169;
  transform: translateY(-1px);
}

.jump-btn:active:not(:disabled) {
  transform: translateY(0);
}

.jump-btn:disabled {
  background: #cbd5e0;
  cursor: not-allowed;
  opacity: 0.6;
}

.query-content {
  padding: 20px;
  margin: 0;
  background: #f8f9fa;
  overflow-x: auto;
  max-height: 400px;
  overflow-y: auto;
}

.query-content code {
  font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
  font-size: 13px;
  line-height: 1.6;
  color: #333;
  white-space: pre-wrap;
  word-wrap: break-word;
}

.es-parser-section {
  margin-top: 12px;
}

.parser-actions {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
}

.parser-result {
  border: 1px solid #e0e0e0;
  border-radius: 12px;
  padding: 16px;
  background: #f8f9fa;
}

.error-text {
  color: #e53e3e;
  font-weight: 600;
}

.placeholder-text {
  color: #718096;
}

.table-wrapper {
  overflow: auto;
}

.parser-table {
  width: 100%;
  border-collapse: collapse;
}

.parser-table th,
.parser-table td {
  border: 1px solid #e2e8f0;
  padding: 10px 12px;
  text-align: left;
  font-size: 13px;
}

.parser-table th {
  background: #eef2ff;
  color: #3b3bb3;
  font-weight: 700;
}

.parser-table tbody tr:nth-child(odd) {
  background: #fff;
}

.parser-table tbody tr:nth-child(even) {
  background: #f7fafc;
}

@media (max-width: 768px) {
  .container {
    padding: 20px;
  }
  
  .text-parser-section {
    margin-bottom: 20px;
  }
  
  .input-section {
    grid-template-columns: 1fr;
  }
  
  .title {
    font-size: 24px;
  }
  
  .text-input {
    font-size: 13px;
  }
}
</style>

