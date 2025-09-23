import { Controller } from "@hotwired/stimulus"

// Dropdown controller for navigation menus
export default class extends Controller {
  static targets = ["trigger", "menu"]
  static values = { 
    closeOnClickOutside: { type: Boolean, default: true },
    closeOnEscape: { type: Boolean, default: true }
  }

  connect() {
    this.isOpen = false
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
  }

  disconnect() {
    this.removeEventListeners()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (this.isOpen) return
    
    this.isOpen = true
    this.menuTarget.classList.remove("opacity-0", "invisible")
    this.menuTarget.classList.add("opacity-100", "visible")
    
    // Add event listeners
    if (this.closeOnClickOutsideValue) {
      document.addEventListener("click", this.boundCloseOnClickOutside)
    }
    
    if (this.closeOnEscapeValue) {
      document.addEventListener("keydown", this.boundCloseOnEscape)
    }
    
    // Focus management for accessibility
    this.menuTarget.setAttribute("aria-expanded", "true")
    
    // Animate trigger icon if it exists
    const icon = this.triggerTarget.querySelector("svg")
    if (icon) {
      icon.style.transform = "rotate(180deg)"
    }
  }

  close() {
    if (!this.isOpen) return
    
    this.isOpen = false
    this.menuTarget.classList.remove("opacity-100", "visible")
    this.menuTarget.classList.add("opacity-0", "invisible")
    
    // Remove event listeners
    this.removeEventListeners()
    
    // Focus management for accessibility
    this.menuTarget.setAttribute("aria-expanded", "false")
    
    // Reset trigger icon
    const icon = this.triggerTarget.querySelector("svg")
    if (icon) {
      icon.style.transform = "rotate(0deg)"
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
      this.triggerTarget.focus()
    }
  }

  removeEventListeners() {
    document.removeEventListener("click", this.boundCloseOnClickOutside)
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

  // Handle hover events for desktop
  mouseEnter() {
    // Only auto-open on hover for larger screens
    if (window.innerWidth >= 1024) {
      this.open()
    }
  }

  mouseLeave() {
    // Only auto-close on hover for larger screens
    if (window.innerWidth >= 1024) {
      // Add a small delay to prevent accidental closes
      setTimeout(() => {
        if (!this.element.matches(':hover')) {
          this.close()
        }
      }, 100)
    }
  }

  // Handle click events for mobile
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
}
