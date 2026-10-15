import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["btnEs", "btnEn"]

  connect() {
    this.injectGoogleTranslateScript()
    const savedLocale = localStorage.getItem("app_locale") || "en"
    this.updateButtons(savedLocale)

    // Esperar a que el script de traducción esté disponible para aplicar el idioma guardado
    const checkInterval = setInterval(() => {
      const select = document.querySelector(".goog-te-combo")
      if (select) {
        clearInterval(checkInterval)
        if (savedLocale === "en") {
          this.applyLanguage("en")
        }
      }
    }, 200)
  }

  setSpanish(e) {
    if (e) e.preventDefault()
    this.applyLanguage("es")
  }

  setEnglish(e) {
    if (e) e.preventDefault()
    this.applyLanguage("en")
  }

  applyLanguage(lang) {
    localStorage.setItem("app_locale", lang)
    this.updateButtons(lang)

    const select = document.querySelector(".goog-te-combo")
    if (select) {
      select.value = lang
      select.dispatchEvent(new Event("change"))
    }
  }

  updateButtons(lang) {
    if (this.hasBtnEsTarget && this.hasBtnEnTarget) {
      if (lang === "es") {
        this.btnEsTarget.className = "cursor-pointer text-amber-400 font-bold transition"
        this.btnEnTarget.className = "cursor-pointer text-stone-400 hover:text-white transition"
      } else {
        this.btnEnTarget.className = "cursor-pointer text-amber-400 font-bold transition"
        this.btnEsTarget.className = "cursor-pointer text-stone-400 hover:text-white transition"
      }
    }
  }

  injectGoogleTranslateScript() {
    if (document.getElementById("google-translate-script")) return

    window.googleTranslateElementInit = () => {
      new window.google.translate.TranslateElement({
        pageLanguage: "es",
        includedLanguages: "en,es",
        autoDisplay: false
      }, "google_translate_element")
    }

    const script = document.createElement("script")
    script.id = "google_translate_script"
    script.src = "//translate.google.com/translate_a/element.js?cb=googleTranslateElementInit"
    document.body.appendChild(script)
  }
}