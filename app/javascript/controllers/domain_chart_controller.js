import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    data: Array
  }

  connect() {
    this.canvas = document.getElementById("domainStatusChart")
    if (!this.canvas || typeof this.canvas.getContext !== "function") return

    this.ctx = this.canvas.getContext("2d")
    this.currentRange = "all"
    this.activePoint = null

    this.boundOnMouseMove = this.onMouseMove.bind(this)
    this.boundOnMouseLeave = this.onMouseLeave.bind(this)

    this.canvas.addEventListener("mousemove", this.boundOnMouseMove)
    this.canvas.addEventListener("mouseleave", this.boundOnMouseLeave)

    this.resizeObserver = new ResizeObserver(() => {
      this.resizeCanvas()
      this.drawChart()
    })
    this.resizeObserver.observe(this.canvas.parentElement)

    this.resizeCanvas()
    this.drawChart()
  }

  disconnect() {
    if (this.resizeObserver) this.resizeObserver.disconnect()
    if (this.canvas) {
      this.canvas.removeEventListener("mousemove", this.boundOnMouseMove)
      this.canvas.removeEventListener("mouseleave", this.boundOnMouseLeave)
    }
  }

  resizeCanvas() {
    if (!this.canvas) return
    const rect = this.canvas.parentElement.getBoundingClientRect()
    const dpr = window.devicePixelRatio || 1

    this.width = rect.width
    this.height = rect.height || 300

    this.canvas.width = this.width * dpr
    this.canvas.height = this.height * dpr
    this.canvas.style.width = `${this.width}px`
    this.canvas.style.height = `${this.height}px`

    this.ctx.resetTransform()
    this.ctx.scale(dpr, dpr)
  }

  changeTimeRange(event) {
    this.currentRange = event.target.value
    this.activePoint = null
    this.drawChart()
  }

  filterData() {
    const raw = this.dataValue || []
    if (this.currentRange === "all") return raw

    const now = new Date().getTime()
    const ranges = {
      week: 7 * 86400000,
      month: 30 * 86400000,
      "3months": 90 * 86400000,
      year: 365 * 86400000
    }
    const delta = ranges[this.currentRange] || 0
    return raw.filter(d => (now - new Date(d.recorded_at).getTime()) <= delta)
  }

  drawChart() {
    if (!this.ctx) return
    const width = this.width
    const height = this.height
    this.ctx.clearRect(0, 0, width, height)

    const points = this.filterData()

    if (!points || points.length === 0) {
      this.ctx.fillStyle = "#9ca3af"
      this.ctx.font = "14px Inter, system-ui, sans-serif"
      this.ctx.textAlign = "center"
      this.ctx.fillText("No hay registros disponibles para el período seleccionado", width / 2, height / 2)
      return
    }

    const padding = { top: 30, right: 25, bottom: 50, left: 65 }
    const plotW = width - padding.left - padding.right
    const plotH = height - padding.top - padding.bottom

    const latencies = points.map(p => Number(p.response_time_ms) || 0)
    const maxVal = Math.max(...latencies, 100)
    const yMax = Math.ceil((maxVal * 1.25) / 50) * 50

    const steps = 4
    this.ctx.strokeStyle = "#f3f4f6"
    this.ctx.lineWidth = 1
    this.ctx.fillStyle = "#6b7280"
    this.ctx.font = "12px Inter, system-ui, sans-serif"
    this.ctx.textAlign = "right"

    for (let i = 0; i <= steps; i++) {
      const yVal = Math.round((yMax / steps) * i)
      const yPos = padding.top + plotH - (plotH / steps) * i

      this.ctx.beginPath()
      this.ctx.moveTo(padding.left, yPos)
      this.ctx.lineTo(width - padding.right, yPos)
      this.ctx.stroke()

      this.ctx.fillText(`${yVal} ms`, padding.left - 12, yPos + 4)
    }

    const coords = points.map((p, i) => {
      const x = points.length === 1
        ? padding.left + plotW / 2
        : padding.left + (plotW / (points.length - 1)) * i
      const lat = Number(p.response_time_ms) || 0
      const y = padding.top + plotH - (lat / yMax) * plotH
      return { x, y, data: p }
    })
    this.computedCoords = coords

    if (coords.length > 1) {
      const gradient = this.ctx.createLinearGradient(0, padding.top, 0, padding.top + plotH)
      gradient.addColorStop(0, "rgba(99, 102, 241, 0.25)")
      gradient.addColorStop(1, "rgba(99, 102, 241, 0.0)")

      this.ctx.beginPath()
      this.ctx.moveTo(coords[0].x, padding.top + plotH)
      coords.forEach(pt => this.ctx.lineTo(pt.x, pt.y))
      this.ctx.lineTo(coords[coords.length - 1].x, padding.top + plotH)
      this.ctx.closePath()
      this.ctx.fillStyle = gradient
      this.ctx.fill()
    }

    this.ctx.beginPath()
    this.ctx.strokeStyle = "#6366f1"
    this.ctx.lineWidth = 2
    this.ctx.lineJoin = "round"
    this.ctx.lineCap = "round"

    coords.forEach((pt, i) => {
      if (i === 0) this.ctx.moveTo(pt.x, pt.y)
      else this.ctx.lineTo(pt.x, pt.y)
    })
    this.ctx.stroke()

    const showAllPoints = coords.length <= 40
    coords.forEach(pt => {
      const isDown = pt.data.status !== "up"
      if (showAllPoints || isDown) {
        this.ctx.beginPath()
        this.ctx.arc(pt.x, pt.y, isDown ? 4.5 : 2.5, 0, 2 * Math.PI)
        this.ctx.fillStyle = isDown ? "#ef4444" : "#6366f1"
        this.ctx.fill()
        this.ctx.strokeStyle = "#ffffff"
        this.ctx.lineWidth = 1.5
        this.ctx.stroke()
      }
    })

    this.ctx.fillStyle = "#6b7280"
    this.ctx.font = "11px Inter, system-ui, sans-serif"
    this.ctx.textAlign = "left"

    if (points.length > 0) {
      const firstDate = new Date(points[0].recorded_at).toLocaleDateString("es-ES", {
        day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit"
      })
      this.ctx.fillText(firstDate, padding.left, height - 15)

      if (points.length > 1) {
        const lastDate = new Date(points[points.length - 1].recorded_at).toLocaleDateString("es-ES", {
          day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit"
        })
        this.ctx.textAlign = "right"
        this.ctx.fillText(lastDate, width - padding.right, height - 15)
      }
    }

    if (this.activePoint) {
      this.renderTooltip(this.activePoint, padding, width, height)
    }
  }

  onMouseMove(e) {
    if (!this.computedCoords || this.computedCoords.length === 0) return
    const rect = this.canvas.getBoundingClientRect()
    const mouseX = e.clientX - rect.left

    let closest = this.computedCoords[0]
    let minDist = Math.abs(closest.x - mouseX)

    for (let i = 1; i < this.computedCoords.length; i++) {
      const dist = Math.abs(this.computedCoords[i].x - mouseX)
      if (dist < minDist) {
        minDist = dist
        closest = this.computedCoords[i]
      }
    }

    if (minDist < 30) {
      this.activePoint = closest
    } else {
      this.activePoint = null
    }
    this.drawChart()
  }

  onMouseLeave() {
    this.activePoint = null
    this.drawChart()
  }

  renderTooltip(pt, padding, width, height) {
    this.ctx.beginPath()
    this.ctx.setLineDash([4, 4])
    this.ctx.strokeStyle = "#94a3b8"
    this.ctx.lineWidth = 1
    this.ctx.moveTo(pt.x, padding.top)
    this.ctx.lineTo(pt.x, height - padding.bottom)
    this.ctx.stroke()
    this.ctx.setLineDash([])

    this.ctx.beginPath()
    this.ctx.arc(pt.x, pt.y, 5, 0, 2 * Math.PI)
    this.ctx.fillStyle = pt.data.status === "up" ? "#4f46e5" : "#ef4444"
    this.ctx.fill()
    this.ctx.strokeStyle = "#ffffff"
    this.ctx.lineWidth = 2
    this.ctx.stroke()

    const latText = `${pt.data.response_time_ms || 0} ms`
    const statusText = pt.data.status === "up" ? "UP" : "DOWN"
    const dateText = new Date(pt.data.recorded_at).toLocaleString("es-ES", {
      day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit", second: "2-digit"
    })

    this.ctx.font = "bold 12px Inter, system-ui, sans-serif"
    const textWidth = Math.max(
      this.ctx.measureText(latText).width + 45,
      this.ctx.measureText(dateText).width + 20
    )
    const boxW = Math.max(textWidth, 140)
    const boxH = 55

    let boxX = pt.x + 12
    if (boxX + boxW > width - 10) boxX = pt.x - boxW - 12
    let boxY = pt.y - boxH / 2
    if (boxY < padding.top) boxY = padding.top
    if (boxY + boxH > height - padding.bottom) boxY = height - padding.bottom - boxH

    this.ctx.fillStyle = "rgba(15, 23, 42, 0.9)"
    this.roundRect(this.ctx, boxX, boxY, boxW, boxH, 6)
    this.ctx.fill()

    this.ctx.textAlign = "left"
    this.ctx.fillStyle = "#ffffff"
    this.ctx.font = "bold 12px Inter, system-ui, sans-serif"
    this.ctx.fillText(latText, boxX + 10, boxY + 20)

    this.ctx.fillStyle = pt.data.status === "up" ? "#4ade80" : "#f87171"
    this.ctx.font = "bold 11px Inter, system-ui, sans-serif"
    this.ctx.fillText(`(${statusText})`, boxX + 68, boxY + 20)

    this.ctx.fillStyle = "#94a3b8"
    this.ctx.font = "10px Inter, system-ui, sans-serif"
    this.ctx.fillText(dateText, boxX + 10, boxY + 40)
  }

  roundRect(ctx, x, y, w, h, r) {
    ctx.beginPath()
    ctx.moveTo(x + r, y)
    ctx.arcTo(x + w, y, x + w, y + h, r)
    ctx.arcTo(x + w, y + h, x, y + h, r)
    ctx.arcTo(x, y + h, x, y, r)
    ctx.arcTo(x, y, x + w, y, r)
    ctx.closePath()
  }
}
