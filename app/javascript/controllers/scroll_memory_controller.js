// app/javascript/controllers/scroll_memory_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  
  connect() {
    // Ripristina scroll al caricamento
    this.restoreScroll()
    
    // Salva scroll ogni volta che scrolli
    window.addEventListener('scroll', this.saveScroll.bind(this))
  }

  disconnect() {
    window.removeEventListener('scroll', this.saveScroll.bind(this))
  }

  saveScroll() {
    sessionStorage.setItem('scrollY', window.scrollY.toString())
  }

  restoreScroll() {
    const savedY = sessionStorage.getItem('scrollY')
    if (savedY) {
      setTimeout(() => {
        window.scrollTo(0, parseInt(savedY))
      }, 50)
    }
  }
}
