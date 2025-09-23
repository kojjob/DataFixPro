import { Controller } from "@hotwired/stimulus"

// Interactive dashboard preview with Framer-like animations
export default class extends Controller {
  static targets = ["chart", "metric", "pulse", "progress"]
  static values = { 
    autoplay: { type: Boolean, default: true },
    interval: { type: Number, default: 3000 }
  }

  connect() {
    this.reduced = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
    if (this.reduced) return

    this.animationFrame = null
    this.intervalId = null
    this.currentStep = 0
    this.steps = [
      { metrics: [1247, 89, 156, 23], progress: [75, 45, 92, 67] },
      { metrics: [1389, 94, 178, 31], progress: [82, 52, 89, 74] },
      { metrics: [1456, 97, 189, 28], progress: [88, 58, 95, 81] },
      { metrics: [1523, 91, 201, 35], progress: [91, 61, 87, 78] }
    ]

    this.startAnimations()
    if (this.autoplayValue) {
      this.startAutoplay()
    }
  }

  disconnect() {
    this.stopAnimations()
    this.stopAutoplay()
  }

  startAnimations() {
    // Animate chart bars
    this.chartTargets.forEach((chart, index) => {
      const bars = chart.querySelectorAll('[data-bar]')
      bars.forEach((bar, barIndex) => {
        const delay = (index * 200) + (barIndex * 100)
        setTimeout(() => {
          bar.style.transform = 'scaleY(1)'
          bar.style.opacity = '1'
        }, delay)
      })
    })

    // Animate pulse indicators
    this.pulseTargets.forEach((pulse, index) => {
      setTimeout(() => {
        pulse.classList.add('animate-pulse')
      }, index * 300)
    })

    this.animateMetrics()
  }

  startAutoplay() {
    this.intervalId = setInterval(() => {
      this.nextStep()
    }, this.intervalValue)
  }

  stopAutoplay() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
  }

  stopAnimations() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame)
      this.animationFrame = null
    }
  }

  nextStep() {
    this.currentStep = (this.currentStep + 1) % this.steps.length
    this.animateMetrics()
    this.animateProgress()
  }

  animateMetrics() {
    const currentData = this.steps[this.currentStep]
    
    this.metricTargets.forEach((metric, index) => {
      if (currentData.metrics[index]) {
        this.animateNumber(metric, currentData.metrics[index])
      }
    })
  }

  animateProgress() {
    const currentData = this.steps[this.currentStep]
    
    this.progressTargets.forEach((progress, index) => {
      if (currentData.progress[index]) {
        const bar = progress.querySelector('[data-progress-bar]')
        if (bar) {
          bar.style.width = `${currentData.progress[index]}%`
        }
      }
    })
  }

  animateNumber(element, targetValue) {
    const startValue = parseInt(element.textContent.replace(/,/g, '')) || 0
    const duration = 1000
    const startTime = performance.now()

    const animate = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / duration, 1)
      
      // Easing function (ease-out)
      const easeOut = 1 - Math.pow(1 - progress, 3)
      const currentValue = Math.round(startValue + (targetValue - startValue) * easeOut)
      
      element.textContent = currentValue.toLocaleString()
      
      if (progress < 1) {
        this.animationFrame = requestAnimationFrame(animate)
      }
    }

    this.animationFrame = requestAnimationFrame(animate)
  }

  // Manual controls
  pause() {
    this.stopAutoplay()
  }

  play() {
    if (!this.intervalId) {
      this.startAutoplay()
    }
  }

  reset() {
    this.currentStep = 0
    this.animateMetrics()
    this.animateProgress()
  }
}
