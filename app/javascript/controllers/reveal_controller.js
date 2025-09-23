import { Controller } from "@hotwired/stimulus"

// Scroll-reveal with progressive enhancement.
// Content is visible by default. If animations are allowed and supported,
// we apply an initial hidden state, then reveal on intersect.
export default class extends Controller {
  static values = { threshold: { type: Number, default: 0.15 } }

  connect() {
    this.targets = Array.from(this.element.querySelectorAll("[data-reveal]"))

    // Respect reduced motion and lack of IntersectionObserver (older browsers)
    const reduced = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
    const supported = "IntersectionObserver" in window

    if (reduced || !supported) return // Do nothing; keep everything visible

    // Apply initial hidden state only when JS is active and animations are allowed
    // Use rAF to avoid layout thrash during initial paint
    requestAnimationFrame(() => {
      this.targets.forEach(el => {
        el.classList.add("opacity-0", "translate-y-6")
      })

      this.observer = new IntersectionObserver(this.onIntersect.bind(this), {
        threshold: this.thresholdValue
      })
      this.targets.forEach(el => this.observer.observe(el))
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  onIntersect(entries) {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return
      const el = entry.target
      el.classList.remove("opacity-0", "translate-y-6")
      el.classList.add("opacity-100", "translate-y-0")
      this.observer.unobserve(el)
    })
  }
}
