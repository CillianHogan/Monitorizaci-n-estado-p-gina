import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    data: Array
  }

  connect() {
    this.initializeChart()
  }

  initializeChart() {
    const canvas = document.getElementById('domainStatusChart')
    this.ctx = canvas.getContext('2d')
    this._filteredData = this.filterDataByTimeRange('all')
    
    // Make it responsive
    const resizeObserver = new ResizeObserver(entries => {
      for (let entry of entries) {
        const { width, height } = entry.contentRect
        canvas.width = width
        canvas.height = height
        this.drawChart()
      }
    })
    
    resizeObserver.observe(canvas.parentElement)
    this.drawChart()
  }

  drawChart() {
    const { width, height } = this.ctx.canvas
    this.ctx.clearRect(0, 0, width, height)
    
    const padding = 40
    const chartWidth = width - padding * 2
    const chartHeight = height - padding * 2
    
    // Draw axes
    this.ctx.beginPath()
    this.ctx.strokeStyle = '#666'
    this.ctx.moveTo(padding, padding)
    this.ctx.lineTo(padding, height - padding)
    this.ctx.lineTo(width - padding, height - padding)
    this.ctx.stroke()
    
    // Plot data points
    if (this._filteredData && this._filteredData.length > 1) {
      const step = chartWidth / (this._filteredData.length - 1)
      
      // Draw line
      this.ctx.beginPath()
      this.ctx.strokeStyle = 'rgb(59, 130, 246)'
      this.ctx.lineWidth = 2
      
      this._filteredData.forEach((point, i) => {
        const x = padding + i * step
        const y = height - padding - (point.status === 'up' ? chartHeight : 0)
        
        if (i === 0) {
          this.ctx.moveTo(x, y)
        } else {
          this.ctx.lineTo(x, y)
        }
      })
      
      this.ctx.stroke()
    }
    
    // Draw Y axis labels
    this.ctx.fillStyle = '#666'
    this.ctx.font = '12px Arial'
    this.ctx.textAlign = 'right'
    this.ctx.fillText('Up', padding - 5, padding + 4)
    this.ctx.fillText('Down', padding - 5, height - padding + 4)
    
    // Draw X axis labels
    this.ctx.textAlign = 'center'
    if (this._filteredData && this._filteredData.length > 1) {
      const step = chartWidth / (this._filteredData.length - 1)
      const labelInterval = Math.max(1, Math.ceil(this._filteredData.length / 5))
      
      this._filteredData.forEach((point, i) => {
        if (i % labelInterval === 0) {
          const x = padding + i * step
          const date = new Date(point.recorded_at).toLocaleDateString('es-ES', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
          })
          this.ctx.fillText(date, x, height - padding + 20)
        }
      })
    }
  }

  changeTimeRange(event) {
    const timeRange = event.target.value
    this._filteredData = this.filterDataByTimeRange(timeRange)
    this.drawChart()
}

  filterDataByTimeRange(timeRange) {
    const now = new Date()
    const data = this.dataValue
    
    if (!data || !Array.isArray(data)) return []
    
    if (timeRange === 'all') return data
    
    const msPerDay = 24 * 60 * 60 * 1000
    const ranges = {
      'week': 7 * msPerDay,
      'month': 30 * msPerDay,
      '3months': 90 * msPerDay,
      '6months': 180 * msPerDay,
      'year': 365 * msPerDay
    }
    
    const cutoffTime = ranges[timeRange] ? now.getTime() - ranges[timeRange] : 0
    
    return data.filter(d => {
      const pointDate = new Date(d.created_at)
      return pointDate.getTime() >= cutoffTime
    })
  }
}