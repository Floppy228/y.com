import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link", "section"]
  static values = { offset: Number }

  connect() {
    this.updateActiveLink()
  }

  scrollToSection(event) {
    event.preventDefault()

    const sectionId = event.currentTarget.dataset.sectionId
    const section = this.sectionTargets.find((target) => target.id === sectionId)
    if (!section) return

    const offset = this.offsetValue || 24
    this.setActiveLink(sectionId)

    const containerRect = this.element.getBoundingClientRect()
    const sectionRect = section.getBoundingClientRect()
    this.element.scrollTop = this.element.scrollTop + sectionRect.top - containerRect.top - offset
  }

  updateActiveLink() {
    const offset = this.offsetValue || 24
    const containerRect = this.element.getBoundingClientRect()

    let currentSection = this.sectionTargets[0]
    this.sectionTargets.forEach((section) => {
      const sectionRect = section.getBoundingClientRect()
      const sectionTop = sectionRect.top - containerRect.top
      if (sectionTop <= offset + 8) currentSection = section
    })

    if (currentSection) this.setActiveLink(currentSection.id)
  }

  setActiveLink(sectionId) {
    this.linkTargets.forEach((link) => {
      const active = link.dataset.sectionId === sectionId

      link.classList.toggle("bg-indigo-500/10", active)
      link.classList.toggle("text-white", active)
      link.classList.toggle("font-semibold", active)
      link.classList.toggle("bg-zinc-900", !active)
      link.classList.toggle("text-zinc-400", !active)
      link.classList.toggle("font-medium", !active)

      const dot = link.querySelector("[data-settings-nav-dot]")
      if (dot) {
        dot.classList.toggle("bg-indigo-500", active)
        dot.classList.toggle("bg-zinc-600", !active)
      }
    })
  }
}
