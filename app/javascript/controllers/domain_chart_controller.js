import { Controller } from "@hotwired/stimulus"
import { Chart } from "chart.js/auto"
import "chartjs-adapter-date-fns"

export default class extends Controller {
  static values = {
    data: Array
  }

  connect() {
    const ctx = document.getElementById('domainStatusChart')
    const statusColors = {
      up: '#22c55e',      // green-500
      down: '#ef4444',    // red-500
      pending: '#f59e0b', // amber-500
      error: '#dc2626'    // red-600
    }

    const data = this.dataValue.map(entry => ({
      x: new Date(entry.recorded_at),
      y: this.getStatusValue(entry.status),
      status: entry.status
    }))

    new Chart(ctx, {
      type: 'line',
      data: {
        datasets: [{
          data: data,
          borderColor: '#6366f1',  // indigo-500
          backgroundColor: '#e0e7ff',  // indigo-100
          tension: 0.1,
          pointBackgroundColor: (context) => {
            if (context.raw) {
              return statusColors[context.raw.status] || '#6b7280'  // gray-500 as fallback
            }
            return '#6b7280'
          }
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const point = context.raw
                return `Status: ${point.status.toUpperCase()}`
              }
            }
          }
        },
        scales: {
          x: {
            type: 'time',
            time: {
              unit: 'hour',
              displayFormats: {
                hour: 'MMM d, h:mm a'
              }
            },
            title: {
              display: true,
              text: 'Time'
            }
          },
          y: {
            beginAtZero: true,
            max: 3,
            ticks: {
              stepSize: 1,
              callback: (value) => this.getStatusLabel(value)
            }
          }
        }
      }
    })
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

  getStatusLabel(value) {
    const labels = {
      3: 'UP',
      2: 'PENDING',
      1: 'DOWN',
      0: 'ERROR'
    }
    return labels[value] || ''
  }
}