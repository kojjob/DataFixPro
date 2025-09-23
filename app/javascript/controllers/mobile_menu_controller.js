import { Controller } from "@hotwired/stimulus"

// Mobile menu controller with smooth animations
export default class extends Controller {
  static targets = ["trigger", "menu", "openIcon", "closeIcon"]

  connect() {
    this.isOpen = false
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
    this.boundCloseOnResize = this.closeOnResize.bind(this)
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
    
    // Show menu
    this.menuTarget.classList.remove("hidden")
    
    // Animate menu appearance
    requestAnimationFrame(() => {
      this.menuTarget.style.opacity = "0"
      this.menuTarget.style.transform = "translateY(-10px)"
      
      requestAnimationFrame(() => {
        this.menuTarget.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"
        this.menuTarget.style.opacity = "1"
        this.menuTarget.style.transform = "translateY(0)"
      })
    })
    
    // Toggle icons
    this.openIconTarget.classList.add("hidden")
    this.closeIconTarget.classList.remove("hidden")
    
    // Prevent body scroll on mobile
    document.body.style.overflow = "hidden"
    
    // Add event listeners
    document.addEventListener("keydown", this.boundCloseOnEscape)
    window.addEventListener("resize", this.boundCloseOnResize)
    
    // Accessibility
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.menuTarget.setAttribute("aria-hidden", "false")
  }

  close() {
    if (!this.isOpen) return
    
    this.isOpen = false
    
    // Animate menu disappearance
    this.menuTarget.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"
    this.menuTarget.style.opacity = "0"
    this.menuTarget.style.transform = "translateY(-10px)"
    
    // Hide menu after animation
    setTimeout(() => {
      this.menuTarget.classList.add("hidden")
      this.menuTarget.style.transition = ""
      this.menuTarget.style.opacity = ""
      this.menuTarget.style.transform = ""
    }, 200)
    
    // Toggle icons
    this.closeIconTarget.classList.add("hidden")
    this.openIconTarget.classList.remove("hidden")
    
    // Restore body scroll
    document.body.style.overflow = ""
    
    // Remove event listeners
    this.removeEventListeners()
    
    // Accessibility
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.menuTarget.setAttribute("aria-hidden", "true")
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
      this.triggerTarget.focus()
    }
  }

  closeOnResize() {
    // Close mobile menu when resizing to desktop
    if (window.innerWidth >= 1024) {
      this.close()
    }
  }

  removeEventListeners() {
    document.removeEventListener("keydown", this.boundCloseOnEscape)
    window.removeEventListener("resize", this.boundCloseOnResize)
  }

  // Handle clicks on menu items
  menuItemClick() {
    // Close menu when a menu item is clicked
    this.close()
  }
}
