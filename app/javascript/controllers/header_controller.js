import { Controller } from "@hotwired/stimulus"

// Enhanced sticky header with smooth transitions and better visibility
export default class extends Controller {
  connect() {
    this.onScroll = this.onScroll.bind(this)
    this.ticking = false

    // Set initial state
    this.update()

    // Listen for scroll events
    window.addEventListener("scroll", this.onScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  onScroll() {
    // Throttle with requestAnimationFrame for smooth performance
    if (this.ticking) return
    this.ticking = true
    requestAnimationFrame(() => {
      this.update()
      this.ticking = false
    })
  }

  update() {
    const scrollY = window.scrollY || window.pageYOffset || 0
    const threshold = 10 // Trigger transition after 10px scroll

    if (scrollY > threshold) {
      // Scrolled state - solid background with blur
      this.element.classList.add(
        "bg-white/98",
        "dark:bg-slate-900/98",
        "backdrop-blur-xl",
        "border-b",
        "border-slate-200/60",
        "dark:border-slate-700/60",
        "shadow-xl",
        "shadow-slate-900/10",
        "dark:shadow-slate-900/30"
      )
      this.element.classList.remove(
        "bg-transparent"
      )

      // Force higher opacity for better visibility
      this.element.style.backgroundColor = 'rgba(255, 255, 255, 0.98)'
      if (document.documentElement.classList.contains('dark')) {
        this.element.style.backgroundColor = 'rgba(15, 23, 42, 0.98)'
      }
    } else {
      // Top of page - transparent background
      this.element.classList.remove(
        "bg-white/98",
        "dark:bg-slate-900/98",
        "backdrop-blur-xl",
        "border-b",
        "border-slate-200/60",
        "dark:border-slate-700/60",
        "shadow-xl",
        "shadow-slate-900/10",
        "dark:shadow-slate-900/30"
      )
      this.element.classList.add(
        "bg-transparent"
      )

      // Reset inline styles
      this.element.style.backgroundColor = ''
    }
  }
}
