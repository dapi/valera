import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

// Регистрируем все компоненты Chart.js (эквивалент chart.js/auto)
Chart.register(...registerables)

// Контроллер для отображения графика активности на дашборде
// Использует Chart.js для рендеринга line chart
export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    const labels = JSON.parse(this.canvasTarget.dataset.chartLabels)
    const values = JSON.parse(this.canvasTarget.dataset.chartValues)

    this.chart = new Chart(this.canvasTarget, {
      type: "line",
      data: {
        labels,
        datasets: [{
          label: "Сообщения",
          data: values,
          borderColor: "#3b82f6",
          backgroundColor: "rgba(59, 130, 246, 0.1)",
          tension: 0.3,
          fill: true,
          pointRadius: 4,
          pointHoverRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "#1f2937",
            titleColor: "#f9fafb",
            bodyColor: "#f9fafb",
            padding: 12,
            cornerRadius: 8
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: { stepSize: 1 },
            grid: { color: "rgba(0, 0, 0, 0.05)" }
          },
          x: {
            grid: { display: false }
          }
        }
      }
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }
}
