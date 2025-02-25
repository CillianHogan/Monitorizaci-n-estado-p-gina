import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    data: Array
  }

  static targets = ["displayMode"]

  initialize() {
    this.chartData = []
    this.displayMode = 'both' // Default to showing both points and lines
  }

  connect() {
    this.canvas = document.getElementById('domainStatusChart')
    this.ctx = this.canvas.getContext('2d')
    this.statusColors = {
      up: '#22c55e',      // green-500
      down: '#ef4444',    // red-500
      pending: '#f59e0b', // amber-500
      error: '#dc2626'    // red-600
    }

    this.chartData = this.dataValue.map(entry => ({
      date: new Date(entry.recorded_at),
      status: entry.status,
      value: this.getStatusValue(entry.status)
    })).sort((a, b) => a.date - b.date)

    this.setupCanvas()
    this.draw()
    this.setupTooltip()
  }

  setupCanvas() {
    // Make canvas responsive
    const resizeObserver = new ResizeObserver(entries => {
      for (const entry of entries) {
        const width = entry.contentRect.width
        const height = entry.contentRect.height
        this.canvas.width = width
        this.canvas.height = height
        this.draw()
      }
    })
    resizeObserver.observe(this.canvas)
  }

  toggleDisplayMode() {
    const modes = ['both', 'points', 'line']
    const currentIndex = modes.indexOf(this.displayMode)
    this.displayMode = modes[(currentIndex + 1) % modes.length]
    this.displayModeTarget.textContent = `Mode: ${this.displayMode.charAt(0).toUpperCase() + this.displayMode.slice(1)}`
    this.draw()
  }

  draw() {
    const { width, height } = this.canvas
    this.ctx.clearRect(0, 0, width, height)

    // Calculate margins
    const margin = { top: 20, right: 30, bottom: 40, left: 50 }
    const plotWidth = width - margin.left - margin.right
    const plotHeight = height - margin.top - margin.bottom

    // Calculate scales
    const timeRange = [this.chartData[0]?.date, this.chartData[this.chartData.length - 1]?.date]
    const xScale = (date) => {
      return margin.left + ((date - timeRange[0]) / (timeRange[1] - timeRange[0])) * plotWidth
    }
    const yScale = (value) => {
      return margin.top + (1 - value / 3) * plotHeight
    }

    // Draw axes
    this.drawAxes(margin, plotWidth, plotHeight)

    // Draw line if mode is 'line' or 'both'
    if (this.displayMode === 'line' || this.displayMode === 'both') {
      this.ctx.beginPath()
      this.ctx.strokeStyle = '#6366f1' // indigo-500
      this.ctx.lineWidth = 2

      this.chartData.forEach((point, i) => {
        const x = xScale(point.date)
        const y = yScale(point.value)

        if (i === 0) {
          this.ctx.moveTo(x, y)
        } else {
          this.ctx.lineTo(x, y)
        }
      })

      this.ctx.stroke()
    }

    // Draw points if mode is 'points' or 'both'
    if (this.displayMode === 'points' || this.displayMode === 'both') {
      this.chartData.forEach(point => {
        const x = xScale(point.date)
        const y = yScale(point.value)

        this.ctx.fillStyle = this.statusColors[point.status]
        this.ctx.beginPath()
        this.ctx.arc(x, y, 4, 0, Math.PI * 2)
        this.ctx.fill()
      })
    }
  }

  drawAxes(margin, plotWidth, plotHeight) {
    const { width, height } = this.canvas
    this.ctx.strokeStyle = '#9ca3af' // gray-400
    this.ctx.fillStyle = '#4b5563' // gray-600
    this.ctx.font = '12px system-ui'

    // Y-axis
    this.ctx.beginPath()
    this.ctx.moveTo(margin.left, margin.top)
    this.ctx.lineTo(margin.left, height - margin.bottom)
    this.ctx.stroke()

    // Y-axis labels
    const labels = ['ERROR', 'DOWN', 'PENDING', 'UP']
    labels.forEach((label, i) => {
      const y = margin.top + (1 - i / 3) * plotHeight
      this.ctx.fillText(label, 5, y + 4)
    })

    // X-axis
    this.ctx.beginPath()
    this.ctx.moveTo(margin.left, height - margin.bottom)
    this.ctx.lineTo(width - margin.right, height - margin.bottom)
    this.ctx.stroke()

    // X-axis labels
    const timeLabels = this.chartData.filter((_, i) => i % Math.ceil(this.chartData.length / 5) === 0)
    timeLabels.forEach(point => {
      const x = margin.left + ((point.date - this.chartData[0].date) / 
        (this.chartData[this.chartData.length - 1].date - this.chartData[0].date)) * plotWidth
      const label = point.date.toLocaleString('en-US', { 
        month: 'short', 
        day: 'numeric',
        hour: 'numeric',
        minute: 'numeric'
      })
      this.ctx.save()
      this.ctx.translate(x, height - margin.bottom + 5)
      this.ctx.rotate(Math.PI / 4)
      this.ctx.fillText(label, 0, 0)
      this.ctx.restore()
    })
  }

  setupTooltip() {
    const tooltip = document.createElement('div')
    tooltip.style.display = 'none'
    tooltip.style.position = 'absolute'
    tooltip.style.backgroundColor = 'rgba(255, 255, 255, 0.9)'
    tooltip.style.padding = '8px'
    tooltip.style.border = '1px solid #e5e7eb'
    tooltip.style.borderRadius = '4px'
    tooltip.style.pointerEvents = 'none'
    document.body.appendChild(tooltip)

    this.canvas.addEventListener('mousemove', (event) => {
      const rect = this.canvas.getBoundingClientRect()
      const x = event.clientX - rect.left
      const y = event.clientY - rect.top

      const point = this.findClosestPoint(x, y)
      if (point) {
        tooltip.style.display = 'block'
        tooltip.style.left = `${event.pageX + 10}px`
        tooltip.style.top = `${event.pageY + 10}px`
        tooltip.textContent = `Status: ${point.status.toUpperCase()}`
      } else {
        tooltip.style.display = 'none'
      }
    })

    this.canvas.addEventListener('mouseleave', () => {
      tooltip.style.display = 'none'
    })
  }

  findClosestPoint(x, y) {
    const margin = { top: 20, right: 30, bottom: 40, left: 50 }
    const plotWidth = this.canvas.width - margin.left - margin.right
    const plotHeight = this.canvas.height - margin.top - margin.bottom

    for (const point of this.chartData) {
      const px = margin.left + ((point.date - this.chartData[0].date) / 
        (this.chartData[this.chartData.length - 1].date - this.chartData[0].date)) * plotWidth
      const py = margin.top + (1 - point.value / 3) * plotHeight

      if (Math.hypot(x - px, y - py) < 10) {
        return point
      }
    }
    return null
  }

  getStatusValue(status) {
    const statusValues = {
      up: 3,
      pending: 2,
      down: 1,
      error: 0
    }
    return statusValues[status] || 0
  }
}