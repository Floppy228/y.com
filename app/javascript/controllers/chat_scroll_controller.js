import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
  }

  scrollToBottom() {
    // A double pass handles cases where images/fonts change layout right after load.
    requestAnimationFrame(() => {
      this.element.scrollTop = this.element.scrollHeight

      setTimeout(() => {
        this.element.scrollTop = this.element.scrollHeight
      }, 40)
    })
  }
}

