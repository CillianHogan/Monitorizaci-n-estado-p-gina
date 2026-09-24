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
    if (!canvas) return
    this.ctx = canvas.getContext('2d')
    this._filteredData = this.filterDataByTimeRange('all')

    const resizeObserver = new ResizeObserver(entries => {
      for (let entry of entries) {
        const { width, height } = entry.contentRect
        if (width === 0 || height === 0) return
        canvas.width = width
        canvas.height = height
        this.drawChart()
      }
    })

    resizeObserver.observe(canvas.parentElement)
    this.drawChart()
  }

  drawChart() {
    if (!this.ctx) return
    const { width, height } = this.ctx.canvas
    this.ctx.clearRect(0, 0, width, height)

    const padding = 50
    const bottomPadding = 80
    const chartWidth = width - padding * 2
    const chartHeight = height - padding - bottomPadding

    if (!this._filteredData || this._filteredData.length === 0) {
      this.ctx.fillStyle = '#6b7280'
      this.ctx.font = '14px system-ui'
      this.ctx.textAlign = 'center'
      this.ctx.fillText('No hay datos suficientes para graficar en este periodo', width / 2, height / 2)
      return
    }

    const latencies = this._filteredData.map(d => d.response_time_ms || 0)
    const maxLatency = Math.max(...latencies, 500)
    const yMax = Math.ceil(maxLatency * 1.2)

    // Ejes
    this.ctx.beginPath()
    this.ctx.strokeStyle = '#e5e7eb'
    this.ctx.lineWidth = 1

    // Líneas guía horizontales
    const gridSteps = 4
    for (let i = 0; i <= gridSteps; i++) {
      const yVal = Math.round((yMax / gridSteps) * i)
      const yPos = height - bottomPadding - (chartHeight / gridSteps) * i

      this.ctx.moveTo(padding, yPos)
      this.ctx.lineTo(width - padding, yPos)

      this.ctx.fillStyle = '#6b7280'
      this.ctx.font = '11px system-ui'
      this.ctx.textAlign = 'right'
      this.ctx.fillText(`${yVal} ms`, padding - 10, yPos + 4)
    }
    this.ctx.stroke()

    // Trazar línea de latencia
    if (this._filteredData.length > 1) {
      const step = chartWidth / (this._filteredData.length - 1)

      this.ctx.beginPath()
      this.ctx.strokeStyle = '#4f46e5'
      this.ctx.lineWidth = 2

      this._filteredData.forEach((point, i) => {
        const x = padding + i * step
        const lat = point.response_time_ms || 0
        const y = height - bottomPadding - (lat / yMax) * chartHeight

        if (i === 0) {
          this.ctx.moveTo(x, y)
        } else {
          this.ctx.lineTo(x, y)
        }
      })
      this.ctx.stroke()

      // Dibujar puntos con color según estado
      this._filteredData.forEach((point, i) => {
        const x = padding + i * step
        const lat = point.response_time_ms || 0
        const y = height - bottomPadding - (lat / yMax) * chartHeight

        this.ctx.beginPath()
        this.ctx.arc(x, y, 4, 0, 2 * Math.PI)
        this.ctx.fillStyle = point.status === 'up' ? '#16a34a' : '#dc2626'
        this.ctx.fill()
        this.ctx.strokeStyle = '#ffffff'
        this.ctx.lineWidth = 1.5
        this.ctx.stroke()
      })
    } else if (this._filteredData.length === 1) {
      const point = this._filteredData[0]
      const lat = point.response_time_ms || 0
      const x = width / 2
      const y = height - bottomPadding - (lat / yMax) * chartHeight

      this.ctx.beginPath()
      this.ctx.arc(x, y, 5, 0, 2 * Math.PI)
      this.ctx.fillStyle = point.status === 'up' ? '#16a34a' : '#dc2626'
      this.ctx.fill()
    }

    // Fechas en eje X
    if (this._filteredData.length > 1) {
      const step = chartWidth / (this._filteredData.length - 1)
      this.drawTimestamp(this._filteredData[0], padding, height, bottomPadding)
      this.drawTimestamp(this._filteredData[this._filteredData.length - 1], padding + chartWidth, height, bottomPadding)
    }
  }

  drawTimestamp(point, x, height, bottomPadding) {
    if (!point || !point.recorded_at) return
    const date = new Date(point.recorded_at).toLocaleDateString('es-ES', {
      day: '2-digit',
      month: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    })
    this.ctx.fillStyle = '#6b7280'
    this.ctx.save()
    this.ctx.translate(x, height - bottomPadding + 35)
    this.ctx.rotate(35 * Math.PI / 180)
    this.ctx.textAlign = 'left'
    this.ctx.fillText(date, 0, 0)
    this.ctx.restore()
  }

  changeTimeRange(event) {
    this._filteredData = this.filterDataByTimeRange(event.target.value)
    this.drawChart()
  }

  filterDataByTimeRange(range) {
    const now = new Date()
    const data = this.dataValue || []

    switch (range) {
      case 'week':
        return data.filter(d => new Date(d.recorded_at) > new Date(now - 7 * 24 * 60 * 60 * 1000))
      case 'month':
        return data.filter(d => new Date(d.recorded_at) > new Date(now - 30 * 24 * 60 * 60 * 1000))
      case '3months':
        return data.filter(d => new Date(d.recorded_at) > new Date(now - 90 * 24 * 60 * 60 * 1000))
      case 'year':
        return data.filter(d => new Date(d.recorded_at) > new Date(now - 365 * 24 * 60 * 60 * 1000))
      default:
        return data
    }
  }
}
