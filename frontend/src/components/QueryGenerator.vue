<template>
  <div class="query-generator">
    <div class="container">
      <h1 class="title">报错pair查询语句生成器</h1>
      
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
            <button @click="copyToClipboard(queries.mysql, 'mysql')" class="copy-btn">
              {{ copyStatus.mysql ? '已复制!' : '复制' }}
            </button>
          </div>
          <pre class="query-content"><code>{{ queries.mysql || '等待输入...' }}</code></pre>
        </div>

        <!-- ES 查询 -->
        <div class="query-card">
          <div class="query-header">
            <h2>Elasticsearch 查询</h2>
            <button @click="copyToClipboard(queries.es, 'es')" class="copy-btn">
              {{ copyStatus.es ? '已复制!' : '复制' }}
            </button>
          </div>
          <pre class="query-content"><code>{{ queries.es || '等待输入...' }}</code></pre>
        </div>

        <!-- API 请求 -->
        <div class="query-card">
          <div class="query-header">
            <h2>API 请求</h2>
            <button @click="copyToClipboard(queries.api, 'api')" class="copy-btn">
              {{ copyStatus.api ? '已复制!' : '复制' }}
            </button>
          </div>
          <pre class="query-content"><code>{{ queries.api || '等待输入...' }}</code></pre>
        </div>

        <!-- Log 查询 1 -->
        <div class="query-card">
          <div class="query-header">
            <h2>Log 查询 - 置灰拦截</h2>
            <button @click="copyToClipboard(queries.log1, 'log1')" class="copy-btn">
              {{ copyStatus.log1 ? '已复制!' : '复制' }}
            </button>
          </div>
          <pre class="query-content"><code>{{ queries.log1 || '等待输入...' }}</code></pre>
        </div>

        <!-- Log 查询 2 -->
        <div class="query-card">
          <div class="query-header">
            <h2>Log 查询 - 下游接口查询ES bool值构造</h2>
            <button @click="copyToClipboard(queries.log2, 'log2')" class="copy-btn">
              {{ copyStatus.log2 ? '已复制!' : '复制' }}
            </button>
          </div>
          <pre class="query-content"><code>{{ queries.log2 || '等待输入...' }}</code></pre>
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
        log2: ''
      },
      copyStatus: {
        mysql: false,
        es: false,
        api: false,
        log1: false,
        log2: false
      },
      debounceTimer: null,
      textParseTimer: null
    }
  },
  methods: {
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
        this.queries = {
          mysql: '',
          es: '',
          api: '',
          log1: '',
          log2: ''
        }
        return
      }

      try {
        const response = await axios.post('/api/generate', this.formData)
        this.queries = response.data
      } catch (error) {
        console.error('生成查询语句失败:', error)
        // 可以添加错误提示
      }
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

