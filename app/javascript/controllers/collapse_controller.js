// app/javascript/controllers/collapse_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  
  connect() {
    console.log("Collapse controller connected")
  }

  // Metodo originale per toggle solo visivo (senza persistenza)
  toggle(event) {
    const button = event.currentTarget
    const targetId = button.dataset.targetId
    const content = document.getElementById(targetId)
    const arrow = button.querySelector('svg')
    
    if (!content || !arrow) return
    
    if (content.classList.contains('collapsed')) {
      content.classList.remove('collapsed')
      arrow.style.transform = 'rotate(0deg)'
    } else {
      content.classList.add('collapsed')
      arrow.style.transform = 'rotate(-90[48;33;190;1056;2660tdeg)'
    }
  }

  // Nuovo metodo con persistenza nel database
  toggleWithPersistence(event) {
    const button = event.currentTarget
    const itemId = button.dataset.itemId
    const targetId = button.dataset.targetId
    const content = document.getElementById(targetId)
    const arrow = button.querySelector('svg')
    
    if (!content || !arrow || !itemId) return

    // Prima aggiorna l'UI immediatamente per responsività
    const isCurrentlyExpanded = !content.classList.contains('collapsed')
    
    if (isCurrentlyExpanded) {
      content.classList.add('collapsed')
      arrow.style.transform = 'rotate(-90deg)'
    } else {
      content.classList.remove('collapsed')
      arrow.style.transform = 'rotate(0deg)'
    }

    // Poi salva lo stato nel database
    fetch(`/list_items/${itemId}/toggle_expanded`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      console.log(`Item ${itemId} expanded state saved:`, data.expanded)
      // Se c'è discrepanza tra UI e database, correggi l'UI
      if (data.expanded !== !content.classList.contains('collapsed')) {
        if (data.expanded) {
          content.classList.remove('collapsed')
          arrow.style.transform = 'rotate(0deg)'
        } else {
          content.classList.add('collapsed')
          arrow.style.transform = 'rotate(-90deg)'
        }
      }
    })
    .catch(error => {
      console.error('Errore nel salvare lo stato:', error)
      // In caso di errore, ripristina lo stato precedente
      if (isCurrentlyExpanded) {
        content.classList.remove('collapsed')
        arrow.style.transform = 'rotate(0deg)'
      } else {
        content.classList.add('collapsed')
        arrow.style.transform = 'rotate(-90deg)'
      }
    })
  }
  
  expandAll() {
    console.log("🔄 Expand all clicked!")
    const contents = document.querySelectorAll('.collapsible-content')
    const arrows = document.querySelectorAll('.collapse-btn svg')
    
    console.log("Found contents:", contents.length, "arrows:", arrows.length)
    
    contents.forEach(content => {
      content.classList.remove('collapsed')
      console.log("Expanded:", content.id)
    })
    
    arrows.forEach(arrow => {
      arrow.style.transform = 'rotate(0deg)'
    })

    // TODO: Opzionalmente puoi anche salvare tutti gli stati nel database
    // con una chiamata batch se necessario
  }
  
  collapseAll() {
    console.log("🔄 Collapse all clicked!")
    const contents = document.querySelectorAll('.collapsible-content')
    const arrows = document.querySelectorAll('.collapse-btn svg')
    
    console.log("Found contents:", contents.length, "arrows:", arrows.length)
    
    contents.forEach(content => {
      content.classList.add('collapsed')
      console.log("Collapsed:", content.id)
    })
    
    arrows.forEach(arrow => {
      arrow.style.transform = 'rotate(-90deg)'
    })

    // TODO: Opzionalmente puoi anche salvare tutti gli stati nel database
    // con una chiamata batch se necessario
  }
}
