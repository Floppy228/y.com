import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.markRead()
  }

  markRead() {
    const csrf = document.querySelector("[name='csrf-token']")
    fetch("/notifications/read", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrf?.content,
      },
    })
  }
}
