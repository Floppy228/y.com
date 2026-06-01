import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { chatUserId: Number }

  connect() {
    this.observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        for (const node of mutation.addedNodes) {
          if (node.nodeType === Node.ELEMENT_NODE) {
            const senderId = node.getAttribute("data-sender-id")
            if (senderId && Number(senderId) === this.chatUserIdValue) {
              this.markRead()
              return
            }
          }
        }
      }
    })

    this.observer.observe(this.element, { childList: true, subtree: false })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  markRead() {
    const csrf = document.querySelector("[name='csrf-token']")
    fetch("/messages/read", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrf?.content,
      },
      body: JSON.stringify({ sender_id: this.chatUserIdValue }),
    })
  }
}
