import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  static values = { shortcut: String }

  submitOnShortcut(event) {
    if (this.shouldInsertNewline(event)) {
      event.preventDefault()
      this.insertNewline()
      return
    }

    if (!this.shouldSubmit(event)) return

    event.preventDefault()
    if (this.inputTarget.value.trim() === "") return

    this.element.requestSubmit()
  }

  shouldSubmit(event) {
    if (event.isComposing) return false

    const shortcut = this.shortcutValue || "enter"
    if (shortcut === "ctrl_enter") {
      return event.key === "Enter" && event.ctrlKey
    }

    return event.key === "Enter" && !event.shiftKey && !event.ctrlKey && !event.metaKey
  }

  shouldInsertNewline(event) {
    if (event.isComposing || event.key !== "Enter") return false

    const shortcut = this.shortcutValue || "enter"
    if (shortcut === "ctrl_enter") {
      return !event.ctrlKey && !event.metaKey
    }

    return event.ctrlKey
  }

  insertNewline() {
    const input = this.inputTarget
    const start = input.selectionStart
    const end = input.selectionEnd
    const value = input.value

    input.value = `${value.slice(0, start)}\n${value.slice(end)}`
    input.selectionStart = start + 1
    input.selectionEnd = start + 1
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
