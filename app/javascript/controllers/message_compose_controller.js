import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "imagePreview", "imageInput"]
  static values = { shortcut: String }

  submitOnShortcut(event) {
    if (this.shouldInsertNewline(event)) {
      event.preventDefault()
      this.insertNewline()
      return
    }

    if (!this.shouldSubmit(event)) return

    event.preventDefault()

    this.element.requestSubmit()
  }

  previewImage(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      if (this.hasImagePreviewTarget) {
        this.imagePreviewTarget.innerHTML = `
          <div class="relative mb-3 inline-block">
            <img src="${e.target.result}" class="max-h-48 max-w-full rounded-xl object-cover" />
            <button type="button" data-action="message-compose#removeImage" class="absolute -right-2 -top-2 flex h-6 w-6 items-center justify-center rounded-full bg-zinc-800 text-xs text-white hover:bg-red-500">&times;</button>
          </div>`
        this.imagePreviewTarget.classList.remove("hidden")
      }
    }
    reader.readAsDataURL(file)
  }

  removeImage() {
    if (this.hasImageInputTarget) this.imageInputTarget.value = ""
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.innerHTML = ""
      this.imagePreviewTarget.classList.add("hidden")
    }
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
