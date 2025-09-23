import { Controller } from "@hotwired/stimulus"

// Interactive testimonials carousel with auto-play and smooth transitions
export default class extends Controller {
  static targets = ["testimonial", "indicator", "avatar", "quote"]
  static values = { 
    autoPlay: { type: Boolean, default: true },
    interval: { type: Number, default: 5000 },
    currentIndex: { type: Number, default: 0 }
  }

  connect() {
    console.log("Testimonials controller connected")
    this.reduced = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches

    this.isPlaying = false
    this.intervalId = null

    // Initialize immediately
    this.initializeTestimonials()

    // Set up intersection observer after a short delay
    setTimeout(() => {
      this.setupIntersectionObserver()
    }, 100)
  }

  disconnect() {
    this.stopAutoPlay()
    this.observer?.disconnect()
  }

  setupIntersectionObserver() {
    if (!this.reduced) {
      this.observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting && this.autoPlayValue) {
            this.startAutoPlay()
          } else {
            this.stopAutoPlay()
          }
        })
      }, { threshold: 0.3 })

      this.observer.observe(this.element)
    }
  }

  initializeTestimonials() {
    console.log("Initializing testimonials, found:", this.testimonialTargets.length)

    if (this.testimonialTargets.length === 0) {
      console.warn("No testimonial targets found")
      return
    }

    // Show first testimonial, hide others
    this.testimonialTargets.forEach((testimonial, index) => {
      testimonial.style.transition = "opacity 0.5s ease-out, transform 0.5s ease-out"

      if (index === 0) {
        testimonial.classList.add("active")
        testimonial.classList.remove("hidden")
        testimonial.style.opacity = "1"
        testimonial.style.transform = "translateX(0)"
        testimonial.style.position = "relative"
        testimonial.style.display = "block"
      } else {
        testimonial.classList.remove("active")
        testimonial.classList.add("hidden")
        testimonial.style.opacity = "0"
        testimonial.style.transform = "translateX(100px)"
        testimonial.style.position = "absolute"
        testimonial.style.display = "none"
      }
    })

    // Set first indicator as active
    this.updateIndicators(0)

    console.log("Testimonials initialized, current index:", this.currentIndexValue)
  }

  animateIn() {
    // Animate current testimonial elements
    const currentTestimonial = this.testimonialTargets[this.currentIndexValue]
    if (!currentTestimonial) return

    const quote = currentTestimonial.querySelector('[data-testimonials-target="quote"]')
    const avatar = currentTestimonial.querySelector('[data-testimonials-target="avatar"]')
    
    if (quote) {
      quote.style.opacity = "0"
      quote.style.transform = "translateY(20px)"
      
      setTimeout(() => {
        quote.style.transition = "opacity 0.6s ease-out, transform 0.6s ease-out"
        quote.style.opacity = "1"
        quote.style.transform = "translateY(0)"
      }, 200)
    }

    if (avatar) {
      avatar.style.opacity = "0"
      avatar.style.transform = "scale(0.8)"
      
      setTimeout(() => {
        avatar.style.transition = "opacity 0.4s ease-out, transform 0.4s ease-out"
        avatar.style.opacity = "1"
        avatar.style.transform = "scale(1)"
      }, 400)
    }
  }

  startAutoPlay() {
    if (!this.autoPlayValue || this.isPlaying || this.reduced) return

    console.log("Starting auto-play")
    this.isPlaying = true
    this.intervalId = setInterval(() => {
      this.nextTestimonial()
    }, this.intervalValue)
  }

  stopAutoPlay() {
    if (this.intervalId) {
      console.log("Stopping auto-play")
      clearInterval(this.intervalId)
      this.intervalId = null
      this.isPlaying = false
    }
  }

  nextTestimonial() {
    const nextIndex = (this.currentIndexValue + 1) % this.testimonialTargets.length
    console.log("Moving to next testimonial:", nextIndex)
    this.goToTestimonial(nextIndex)
  }

  previousTestimonial() {
    const prevIndex = this.currentIndexValue === 0 
      ? this.testimonialTargets.length - 1 
      : this.currentIndexValue - 1
    this.goToTestimonial(prevIndex)
  }

  goToTestimonial(index) {
    if (index === this.currentIndexValue || !this.testimonialTargets[index]) return

    console.log("Going to testimonial:", index, "from:", this.currentIndexValue)

    const currentTestimonial = this.testimonialTargets[this.currentIndexValue]
    const nextTestimonial = this.testimonialTargets[index]

    // Simple show/hide approach for better reliability
    this.hideTestimonial(currentTestimonial)

    setTimeout(() => {
      this.currentIndexValue = index
      this.showTestimonial(nextTestimonial)
      this.updateIndicators(index)
    }, 300)
  }

  hideTestimonial(testimonial) {
    testimonial.style.transition = "opacity 0.3s ease-out"
    testimonial.style.opacity = "0"

    setTimeout(() => {
      testimonial.classList.remove("active")
      testimonial.classList.add("hidden")
      testimonial.style.display = "none"
    }, 300)
  }

  showTestimonial(testimonial) {
    testimonial.classList.add("active")
    testimonial.classList.remove("hidden")
    testimonial.style.display = "block"
    testimonial.style.opacity = "0"

    requestAnimationFrame(() => {
      testimonial.style.transition = "opacity 0.5s ease-out"
      testimonial.style.opacity = "1"
    })
  }

    // Animate testimonial content
    this.animateTestimonialContent(testimonial)
  }

  animateTestimonialContent(testimonial) {
    const quote = testimonial.querySelector('[data-testimonials-target="quote"]')
    const avatar = testimonial.querySelector('[data-testimonials-target="avatar"]')
    
    if (quote) {
      setTimeout(() => {
        quote.style.opacity = "0"
        quote.style.transform = "translateY(20px)"
        
        requestAnimationFrame(() => {
          quote.style.transition = "opacity 0.4s ease-out, transform 0.4s ease-out"
          quote.style.opacity = "1"
          quote.style.transform = "translateY(0)"
        })
      }, 200)
    }

    if (avatar) {
      setTimeout(() => {
        avatar.style.transform = "scale(0.9)"
        
        requestAnimationFrame(() => {
          avatar.style.transition = "transform 0.3s ease-out"
          avatar.style.transform = "scale(1)"
        })
      }, 300)
    }
  }

  updateIndicators(activeIndex) {
    if (this.indicatorTargets.length === 0) return

    this.indicatorTargets.forEach((indicator, index) => {
      indicator.style.transition = "all 0.3s ease-out"
      if (index === activeIndex) {
        indicator.classList.add("active")
        indicator.style.backgroundColor = "#4f46e5" // indigo-600
        indicator.style.transform = "scale(1.2)"
      } else {
        indicator.classList.remove("active")
        indicator.style.backgroundColor = "#e2e8f0" // slate-200
        indicator.style.transform = "scale(1)"
      }
    })
  }

  // Manual navigation
  selectTestimonial(event) {
    event.preventDefault()
    const index = parseInt(event.currentTarget.dataset.index)
    console.log("Manual selection:", index)

    this.stopAutoPlay()
    this.goToTestimonial(index)

    // Restart auto-play after manual interaction
    setTimeout(() => {
      if (this.autoPlayValue) {
        this.startAutoPlay()
      }
    }, 3000)
  }

  // Pause on hover
  pauseOnHover() {
    this.stopAutoPlay()
  }

  resumeOnLeave() {
    if (this.autoPlayValue) {
      setTimeout(() => {
        this.startAutoPlay()
      }, 1000)
    }
  }

  // Keyboard navigation
  handleKeydown(event) {
    switch(event.key) {
      case 'ArrowLeft':
        event.preventDefault()
        this.previousTestimonial()
        break
      case 'ArrowRight':
        event.preventDefault()
        this.nextTestimonial()
        break
      case ' ':
        event.preventDefault()
        if (this.isPlaying) {
          this.stopAutoPlay()
        } else {
          this.startAutoPlay()
        }
        break
    }
  }
}
