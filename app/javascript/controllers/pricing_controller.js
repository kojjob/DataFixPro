import { Controller } from "@hotwired/stimulus"

// Interactive pricing section with plan switching and animations
export default class extends Controller {
  static targets = ["toggle", "monthlyPrices", "yearlyPrices", "card", "feature"]
  static values = { 
    isYearly: { type: Boolean, default: false },
    animationDuration: { type: Number, default: 300 }
  }

  connect() {
    this.reduced = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
    if (this.reduced) return

    this.setupIntersectionObserver()
    this.animateOnLoad()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  setupIntersectionObserver() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.animateCards()
        }
      })
    }, { threshold: 0.2 })

    this.observer.observe(this.element)
  }

  animateOnLoad() {
    // Stagger card animations on load
    this.cardTargets.forEach((card, index) => {
      card.style.opacity = "0"
      card.style.transform = "translateY(20px)"
      
      setTimeout(() => {
        card.style.transition = "opacity 0.6s ease-out, transform 0.6s ease-out"
        card.style.opacity = "1"
        card.style.transform = "translateY(0)"
      }, index * 150)
    })
  }

  animateCards() {
    this.cardTargets.forEach((card, index) => {
      setTimeout(() => {
        card.classList.add("animate-in")
        this.animateFeatures(card)
      }, index * 100)
    })
  }

  animateFeatures(card) {
    const features = card.querySelectorAll('[data-pricing-target="feature"]')
    features.forEach((feature, index) => {
      setTimeout(() => {
        feature.style.opacity = "1"
        feature.style.transform = "translateX(0)"
      }, index * 50)
    })
  }

  togglePlan(event) {
    event.preventDefault()
    this.isYearlyValue = !this.isYearlyValue
    
    // Update toggle appearance
    this.updateToggle()
    
    // Animate price changes
    this.animatePriceChange()
  }

  updateToggle() {
    const toggle = this.toggleTarget
    const slider = toggle.querySelector('[data-slider]')
    
    if (this.isYearlyValue) {
      slider.style.transform = 'translateX(100%)'
      toggle.classList.add('bg-indigo-600')
      toggle.classList.remove('bg-slate-200')
    } else {
      slider.style.transform = 'translateX(0)'
      toggle.classList.remove('bg-indigo-600')
      toggle.classList.add('bg-slate-200')
    }
  }

  animatePriceChange() {
    // Animate out current prices
    const currentPrices = this.isYearlyValue ? this.monthlyPricesTargets : this.yearlyPricesTargets
    const newPrices = this.isYearlyValue ? this.yearlyPricesTargets : this.monthlyPricesTargets
    
    currentPrices.forEach(price => {
      price.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"
      price.style.opacity = "0"
      price.style.transform = "translateY(-10px)"
    })
    
    // Animate in new prices
    setTimeout(() => {
      currentPrices.forEach(price => {
        price.classList.add("hidden")
      })
      
      newPrices.forEach(price => {
        price.classList.remove("hidden")
        price.style.opacity = "0"
        price.style.transform = "translateY(10px)"
        
        requestAnimationFrame(() => {
          price.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
          price.style.opacity = "1"
          price.style.transform = "translateY(0)"
        })
      })
    }, 200)
  }

  // Card hover effects
  cardHover(event) {
    if (this.reduced) return
    
    const card = event.currentTarget
    card.style.transform = "translateY(-8px) scale(1.02)"
    card.style.boxShadow = "0 25px 50px -12px rgba(0, 0, 0, 0.25)"
    
    // Animate features
    const features = card.querySelectorAll('[data-pricing-target="feature"]')
    features.forEach((feature, index) => {
      setTimeout(() => {
        feature.style.transform = "translateX(4px)"
      }, index * 30)
    })
  }

  cardLeave(event) {
    if (this.reduced) return
    
    const card = event.currentTarget
    card.style.transform = ""
    card.style.boxShadow = ""
    
    // Reset features
    const features = card.querySelectorAll('[data-pricing-target="feature"]')
    features.forEach(feature => {
      feature.style.transform = "translateX(0)"
    })
  }

  // Popular plan pulse effect
  pulsePopular() {
    const popularCard = this.element.querySelector('[data-popular]')
    if (!popularCard || this.reduced) return
    
    popularCard.style.animation = "pulse 2s ease-in-out infinite"
    
    setTimeout(() => {
      popularCard.style.animation = ""
    }, 4000)
  }
}
