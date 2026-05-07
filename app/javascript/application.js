// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

const OPEN_EYE_ICON = `
  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
  <circle cx="12" cy="12" r="3"/>
`

const CLOSED_EYE_ICON = `
  <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
  <line x1="1" y1="1" x2="23" y2="23"/>
`

function setupPasswordToggles() {
  document.querySelectorAll("[data-password-toggle]").forEach((button) => {
    if (button.dataset.passwordToggleBound === "true") return

    button.dataset.passwordToggleBound = "true"

    button.addEventListener("click", () => {
      const input = document.getElementById(button.dataset.passwordToggle)
      if (!input) return

      const showPassword = input.type === "password"
      input.type = showPassword ? "text" : "password"

      const icon = button.querySelector("svg")
      if (icon) icon.innerHTML = showPassword ? CLOSED_EYE_ICON : OPEN_EYE_ICON

      button.setAttribute("aria-pressed", showPassword ? "true" : "false")
      button.setAttribute("aria-label", showPassword ? "Скрыть пароль" : "Показать пароль")
    })
  })
}

document.addEventListener("turbo:load", setupPasswordToggles)
