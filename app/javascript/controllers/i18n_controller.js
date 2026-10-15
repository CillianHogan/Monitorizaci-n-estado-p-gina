import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["btnEs", "btnEn"]

  connect() {
    const savedLocale = localStorage.getItem("app_locale") || "en"
    this.applyLocale(savedLocale)
  }

  setSpanish(e) {
    if (e) e.preventDefault()
    this.applyLocale("es")
  }

  setEnglish(e) {
    if (e) e.preventDefault()
    this.applyLocale("en")
  }

  applyLocale(locale) {
    localStorage.setItem("app_locale", locale)
    document.documentElement.lang = locale

    if (this.hasBtnEsTarget && this.hasBtnEnTarget) {
      if (locale === "es") {
        this.btnEsTarget.className = "cursor-pointer text-amber-400 font-bold transition"
        this.btnEnTarget.className = "cursor-pointer text-stone-400 hover:text-white transition"
      } else {
        this.btnEnTarget.className = "cursor-pointer text-amber-400 font-bold transition"
        this.btnEsTarget.className = "cursor-pointer text-stone-400 hover:text-white transition"
      }
    }

    document.querySelectorAll("[data-i18n-es]").forEach(el => {
      const text = locale === "en" ? el.getAttribute("data-i18n-en") : el.getAttribute("data-i18n-es")
      if (text) {
        el.textContent = text
      }
    })
  }
}