import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.dismiss(), 5000)
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  close() {
    if (this.timeout) clearTimeout(this.timeout)
    this.dismiss()
  }

  dismiss() {
    this.element.remove()
  }
}
