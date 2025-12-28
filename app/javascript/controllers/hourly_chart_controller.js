import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// Контроллер для отображения распределения сообщений по часам суток
// Использует Chart.js для рендеринга horizontal bar chart
export default class extends Controller {
  static targets = ["canvas"]

  connect() {
    const data = JSON.parse(this.canvasTarget.dataset.hourlyChartData)
    const labels = data.labels
    const values = data.values
    const maxValue = Math.max(...values)

    // Генерируем цвета на основе интенсивности
    const backgroundColors = values.map(v => this.getIntensityColor(v, maxValue))

    this.chart = new Chart(this.canvasTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [{
          label: "Сообщений",
          data: values,
          backgroundColor: backgroundColors,
          borderRadius: 4,
          barPercentage: 0.8
        }]
      },
      options: {
        indexAxis: "y",  // горизонтальный bar chart
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
              label: (context) => `${context.raw} сообщений`
            }
          }
        },
        scales: {
          x: {
            beginAtZero: true,
            ticks: { stepSize: 1 },
            grid: { color: "rgba(0, 0, 0, 0.05)" }
          },
          y: {
            grid: { display: false },
            ticks: {
              font: { size: 11 }
            }
          }
        }
      }
    })
  }

  // Возвращает цвет от светло-синего до темно-синего в зависимости от значения
  getIntensityColor(value, maxValue) {
    if (maxValue === 0) return "rgba(59, 130, 246, 0.2)"

    const intensity = value / maxValue
    const alpha = 0.2 + (intensity * 0.8) // от 0.2 до 1.0
    return `rgba(59, 130, 246, ${alpha})`
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }
}
