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
    const bottomPadding = 100
    const rightPadding = 30
    const chartWidth = width - padding * 2 - rightPadding
    const chartHeight = height - padding - bottomPadding
    
    // Draw axes
    this.ctx.beginPath()
    this.ctx.strokeStyle = '#666'
    this.ctx.moveTo(padding, padding)
    this.ctx.lineTo(padding, height - bottomPadding)
    this.ctx.lineTo(width - padding, height - bottomPadding)
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
        const y = height - bottomPadding - (point.status === 'up' ? chartHeight : 0)
        
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
    this.ctx.fillText('Down', padding - 5, height - bottomPadding + 4)
    
    // Draw X axis labels
    this.ctx.textAlign = 'center'
    if (this._filteredData && this._filteredData.length > 1) {
      const step = chartWidth / (this._filteredData.length - 1)
      
      // Always draw first and last timestamps
      this.drawTimestamp({ point: this._filteredData[0], index: 0 }, step, padding, height, bottomPadding)
      this.drawTimestamp(
        { point: this._filteredData[this._filteredData.length - 1], index: this._filteredData.length - 1 },
        step, padding, height, bottomPadding
      )
      
      // Group consecutive error/down points for intermediate timestamps
      let currentGroup = []
      this._filteredData.slice(1, -1).forEach((point, i) => {
        const actualIndex = i + 1 // Adjust index for the sliced array
        if (point.status === 'error' || point.status === 'down') {
          currentGroup.push({ point, index: actualIndex })
        } else if (currentGroup.length > 0) {
          // Display only first and last points of the group
          this.drawTimestamp(currentGroup[0], step, padding, height, bottomPadding)
          if (currentGroup.length > 1) {
            this.drawTimestamp(currentGroup[currentGroup.length - 1], step, padding, height, bottomPadding)
          }
          currentGroup = []
        }
      })
      
      // Handle the last intermediate group if it exists
      if (currentGroup.length > 0) {
        this.drawTimestamp(currentGroup[0], step, padding, height, bottomPadding)
        if (currentGroup.length > 1) {
          this.drawTimestamp(currentGroup[currentGroup.length - 1], step, padding, height, bottomPadding)
        }
      }
    }
  }

  drawTimestamp({ point, index }, step, padding, height, bottomPadding) {
    const x = Math.max(padding, padding + index * step)
    const date = new Date(point.recorded_at).toLocaleDateString('es-ES', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
    this.ctx.fillStyle = point.status === 'error' ? '#dc2626' : '#d97706'
    this.ctx.save()
    this.ctx.translate(x + 30, height - bottomPadding + 50)
    this.ctx.rotate(45 * Math.PI / 180)
    this.ctx.fillText(date, 0, 0)
    this.ctx.restore()
    this.ctx.fillStyle = '#666'
  }

  changeTimeRange(event) {
    this._filteredData = this.filterDataByTimeRange(event.target.value)
    this.drawChart()
  }

  filterDataByTimeRange(range) {
    const now = new Date()
    const data = this.dataValue

    switch (range) {
      case 'week':
        return data.filter(d => new Date(d.recorded_at) > new Date(now - 7 * 24 * 60 * 60 * 1000))
      case 'month':
        return data.filter(d => new Date(d.recorded_at) > new Date(now - 30 * 24 * 60 * 60 * 1000))
      case '3months':
        return data.filter(d => new Date(d.recorded_at) > new Date(now - 90 * 24 * 60 * 60 * 1000))
      case '6months':
        return data.filter(d => new Date(d.recorded_at) > new Date(now - 180 * 24 * 60 * 60 * 1000))
      case 'year':
        return data.filter(d => new Date(d.recorded_at) > new Date(now - 365 * 24 * 60 * 60 * 1000))
      default:
        return data
    }
  }
}