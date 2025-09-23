import { Controller } from "@hotwired/stimulus"

// Enhanced feature showcase with interactive elements
export default class extends Controller {
  static targets = ["card", "icon", "demo"]
  static values = { 
    autoRotate: { type: Boolean, default: true },
    interval: { type: Number, default: 4000 }
  }

  connect() {
    this.reduced = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
    if (this.reduced) return

    this.currentIndex = 0
    this.intervalId = null
    this.setupInteractivity()
    
    if (this.autoRotateValue) {
      this.startAutoRotate()
    }
  }

  disconnect() {
    this.stopAutoRotate()
  }

  setupInteractivity() {
    this.cardTargets.forEach((card, index) => {
      card.addEventListener('mouseenter', () => this.highlightFeature(index))
      card.addEventListener('mouseleave', () => this.resetHighlight(index))
    })
  }

  highlightFeature(index) {
    this.stopAutoRotate()
    
    const card = this.cardTargets[index]
    const icon = this.iconTargets[index]
    const demo = this.demoTargets[index]

    // Enhanced hover effects
    card.style.transform = 'translateY(-8px) scale(1.02)'
    card.style.boxShadow = '0 25px 50px -12px rgba(0, 0, 0, 0.25)'
    
    if (icon) {
      icon.style.transform = 'scale(1.1) rotate(5deg)'
    }

    if (demo) {
      this.animateDemo(demo, index)
    }
  }

  resetHighlight(index) {
    const card = this.cardTargets[index]
    const icon = this.iconTargets[index]

    card.style.transform = ''
    card.style.boxShadow = ''
    
    if (icon) {
      icon.style.transform = ''
    }

    // Restart auto-rotate after a delay
    setTimeout(() => {
      if (this.autoRotateValue) {
        this.startAutoRotate()
      }
    }, 2000)
  }

  animateDemo(demo, featureIndex) {
    // Different animations for each feature
    switch(featureIndex) {
      case 0: // Connect
        this.animateConnections(demo)
        break
      case 1: // Transform
        this.animateTransformation(demo)
        break
      case 2: // Visualize
        this.animateVisualization(demo)
        break
      case 3: // Govern
        this.animateGovernance(demo)
        break
    }
  }

  animateConnections(demo) {
    const dots = demo.querySelectorAll('[data-connection-dot]')
    dots.forEach((dot, index) => {
      setTimeout(() => {
        dot.style.transform = 'scale(1.2)'
        dot.style.opacity = '1'
        setTimeout(() => {
          dot.style.transform = 'scale(1)'
        }, 200)
      }, index * 150)
    })
  }

  animateTransformation(demo) {
    const steps = demo.querySelectorAll('[data-transform-step]')
    steps.forEach((step, index) => {
      setTimeout(() => {
        step.style.opacity = '1'
        step.style.transform = 'translateX(0)'
      }, index * 300)
    })
  }

  animateVisualization(demo) {
    const charts = demo.querySelectorAll('[data-chart-element]')
    charts.forEach((chart, index) => {
      setTimeout(() => {
        chart.style.opacity = '1'
        chart.style.transform = 'scale(1)'
      }, index * 200)
    })
  }

  animateGovernance(demo) {
    const shields = demo.querySelectorAll('[data-security-shield]')
    shields.forEach((shield, index) => {
      setTimeout(() => {
        shield.style.opacity = '1'
        shield.style.transform = 'rotate(0deg) scale(1)'
      }, index * 250)
    })
  }

  startAutoRotate() {
    this.intervalId = setInterval(() => {
      this.rotateFeature()
    }, this.intervalValue)
  }

  stopAutoRotate() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
  }

  rotateFeature() {
    this.currentIndex = (this.currentIndex + 1) % this.cardTargets.length
    this.highlightFeature(this.currentIndex)
    
    setTimeout(() => {
      this.resetHighlight(this.currentIndex)
    }, 1500)
  }
}
