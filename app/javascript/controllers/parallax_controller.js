import { Controller } from "@hotwired/stimulus"

// Simple parallax background for hero. Uses translateY on a target layer.
// Respects prefers-reduced-motion and detaches on disconnect.
export default class extends Controller {
  static targets = ["layer"]
  static values = { speed: { type: Number, default: 0.2 } }

  connect() {
    this.reduced = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
    if (this.reduced || !this.hasLayerTarget) return

    this.ticking = false
    this.onScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  onScroll() {
    if (this.ticking) return
    this.ticking = true
    requestAnimationFrame(() => {
      this.update()
      this.ticking = false
    })
  }

  update() {
    const y = (window.scrollY || window.pageYOffset || 0) * this.speedValue
    this.layerTarget.style.transform = `translate3d(0, ${y}px, 0)`
  }
}

