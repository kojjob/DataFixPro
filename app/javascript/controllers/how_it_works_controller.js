import { Controller } from "@hotwired/stimulus"

// Interactive "How it Works" section with step-by-step animations
export default class extends Controller {
  static targets = ["step", "connector", "illustration"]
  static values = { 
    autoPlay: { type: Boolean, default: true },
    stepDuration: { type: Number, default: 2500 }
  }

  connect() {
    this.reduced = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
    if (this.reduced) return

    this.currentStep = 0
    this.intervalId = null
    this.setupIntersectionObserver()
    
    if (this.autoPlayValue) {
      this.startAutoPlay()
    }
  }

  disconnect() {
    this.stopAutoPlay()
    this.observer?.disconnect()
  }

  setupIntersectionObserver() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.startSequence()
        } else {
          this.stopAutoPlay()
        }
      })
    }, { threshold: 0.3 })

    this.observer.observe(this.element)
  }

  startSequence() {
    // Reset all steps
    this.resetAllSteps()
    
    // Start with first step
    setTimeout(() => {
      this.activateStep(0)
    }, 500)
  }

  startAutoPlay() {
    this.intervalId = setInterval(() => {
      this.nextStep()
    }, this.stepDurationValue)
  }

  stopAutoPlay() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
  }

  nextStep() {
    const nextIndex = (this.currentStep + 1) % this.stepTargets.length
    this.activateStep(nextIndex)
  }

  activateStep(index) {
    // Deactivate current step
    if (this.stepTargets[this.currentStep]) {
      this.deactivateStep(this.currentStep)
    }

    // Activate new step
    this.currentStep = index
    const step = this.stepTargets[index]
    const connector = this.connectorTargets[index]
    const illustration = this.illustrationTargets[index]

    // Step activation
    step.classList.add('active')
    step.style.transform = 'scale(1.05)'
    step.style.boxShadow = '0 20px 40px -12px rgba(0, 0, 0, 0.25)'

    // Connector animation
    if (connector) {
      connector.style.opacity = '1'
      connector.style.transform = 'scaleX(1)'
    }

    // Illustration animation
    if (illustration) {
      this.animateIllustration(illustration, index)
    }

    // Reset after duration
    setTimeout(() => {
      if (this.currentStep === index) {
        this.deactivateStep(index)
      }
    }, this.stepDurationValue - 300)
  }

  deactivateStep(index) {
    const step = this.stepTargets[index]
    const connector = this.connectorTargets[index]

    if (step) {
      step.classList.remove('active')
      step.style.transform = ''
      step.style.boxShadow = ''
    }

    if (connector) {
      connector.style.opacity = '0.3'
      connector.style.transform = 'scaleX(0.8)'
    }
  }

  resetAllSteps() {
    this.stepTargets.forEach((step, index) => {
      this.deactivateStep(index)
    })
  }

  animateIllustration(illustration, stepIndex) {
    const elements = illustration.querySelectorAll('[data-animate]')
    
    elements.forEach((element, index) => {
      setTimeout(() => {
        element.style.opacity = '1'
        element.style.transform = 'scale(1) rotate(0deg)'
        
        // Add step-specific animations
        switch(stepIndex) {
          case 0: // Connect
            element.style.animation = 'pulse 1s ease-in-out'
            break
          case 1: // Build
            element.style.animation = 'slideInRight 0.5s ease-out'
            break
          case 2: // Share
            element.style.animation = 'fadeInUp 0.6s ease-out'
            break
        }
      }, index * 150)
    })

    // Reset animations after step
    setTimeout(() => {
      elements.forEach(element => {
        element.style.animation = ''
        element.style.opacity = '0.6'
        element.style.transform = 'scale(0.9) rotate(-5deg)'
      })
    }, this.stepDurationValue - 500)
  }

  // Manual controls
  goToStep(event) {
    const stepIndex = parseInt(event.currentTarget.dataset.stepIndex)
    this.stopAutoPlay()
    this.activateStep(stepIndex)
    
    // Restart auto-play after manual interaction
    setTimeout(() => {
      if (this.autoPlayValue) {
        this.startAutoPlay()
      }
    }, 3000)
  }
}
