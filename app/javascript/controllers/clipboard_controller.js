import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  copy() {
    const input = document.getElementById('public-status-url')
    input.select()
    document.execCommand('copy')
    
    // Mostrar mensaje de éxito
    const button = this.element.querySelector('button')
    const originalHTML = button.innerHTML
    button.innerHTML = '<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg>'
    button.classList.remove('text-gray-400', 'hover:text-gray-500')
    button.classList.add('text-green-500')
    
    setTimeout(() => {
      button.innerHTML = originalHTML
      button.classList.remove('text-green-500')
      button.classList.add('text-gray-400', 'hover:text-gray-500')
    }, 2000)
  }
}