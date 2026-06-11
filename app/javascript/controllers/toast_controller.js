import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.startTimer()
  }

  disconnect() {
    this.clearTimer()
  }

  startTimer() {
    this.clearTimer()
    this.timeout = setTimeout(() => this.dismiss(), 5000)
  }

  clearTimer() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
  }

  pause() {
    this.clearTimer()
  }

  resume() {
    this.startTimer()
  }

  close() {
    this.clearTimer()
    this.dismiss()
  }

  dismiss() {
    this.element.remove()
  }
}
