// app/javascript/controllers/collapse_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  
  connect() {
    console.log("Collapse controller connected")
  }

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
      arrow.style.transform = 'rotate(-90deg)'
    }
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
  }
}
