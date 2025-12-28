import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Контроллер для отображения графика расходов на LLM
// Использует Chart.js для рендеринга bar chart
export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    const labels = JSON.parse(this.canvasTarget.dataset.costChartLabels)
    const values = JSON.parse(this.canvasTarget.dataset.costChartValues)

    this.chart = new Chart(this.canvasTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [{
          label: "Расходы ($)",
          data: values,
          backgroundColor: "rgba(34, 197, 94, 0.6)",
          borderColor: "#22c55e",
          borderWidth: 1,
          borderRadius: 4
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
            cornerRadius: 8,
            callbacks: {
              label: function(context) {
                return `$${context.parsed.y.toFixed(4)}`
              }
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: { color: "rgba(0, 0, 0, 0.05)" },
            ticks: {
              callback: function(value) {
                return `$${value.toFixed(2)}`
              }
            }
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
