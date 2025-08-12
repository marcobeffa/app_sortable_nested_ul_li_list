// app/javascript/controllers/sortable_controller.js
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["list"]
  static values = { 
    url: String,
    group: String
  }

  connect() {
    console.log("Sortable controller connected!")
    this.initializeSortable()
    
    // Reinizializza quando Turbo aggiorna la pagina
    document.addEventListener('turbo:frame-load', () => {
      setTimeout(() => this.initializeNestedLists(), 100)
    })
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }

  initializeSortable() {
    console.log("Initializing sortable on:", this.listTarget)
    
    this.sortable = Sortable.create(this.listTarget, {
      group: {
        name: this.groupValue || 'nested-sortable',
        pull: true,
        put: true
      },
      animation: 150,
      fallbackOnBody: true,
      swapThreshold: 0.65,
      handle: '.drag-handle',
      ghostClass: 'sortable-ghost',
      chosenClass: 'sortable-chosen',
      dragClass: 'sortable-drag',
      
      // IMPORTANTE: permetti drop anche su liste vuote
      emptyInsertThreshold: 50,
      
      onStart: (evt) => {
        console.log("Drag started:", evt)
        evt.item.classList.add('dragging')
        this.showAllDropZones()
      },
      
      onEnd: (evt) => {
        console.log("Drag ended:", evt)
        evt.item.classList.remove('dragging')
        this.hideAllDropZones()
        this.cleanupPlaceholders(evt.to)
        this.handleSort(evt)
      }
    })
    
    // Inizializza anche le sottoliste
    this.initializeNestedLists()
  }
  
  initializeNestedLists() {
    // Trova tutte le liste annidate che non sono già state inizializzate
    const allLists = this.element.querySelectorAll('ul[data-sortable-target="list"]')
    console.log("Found all lists:", allLists.length)
    
    allLists.forEach(list => {
      if (list === this.listTarget) return // Skip main list
      if (list.sortableInstance) return // Skip already initialized lists
      
      console.log("Initializing nested list:", list, "with parent-id:", list.dataset.parentId)
      
      const sortableInstance = Sortable.create(list, {
        group: {
          name: this.groupValue || 'nested-sortable',
          pull: true,
          put: true
        },
        animation: 150,
        fallbackOnBody: true,
        swapThreshold: 0.65,
        handle: '.drag-handle',
        ghostClass: 'sortable-ghost',
        chosenClass: 'sortable-chosen',
        dragClass: 'sortable-drag',
        
        // CRITICO: permetti drop su liste vuote con soglia alta
        emptyInsertThreshold: 50,
        
        onStart: (evt) => {
          console.log("Nested drag started:", evt)
          this.showAllDropZones()
        },
        
        onEnd: (evt) => {
          console.log("Nested drag ended:", evt)
          this.hideAllDropZones()
          this.cleanupPlaceholders(evt.to)
          this.handleSort(evt)
        }
      })
      
      // Marca la lista come inizializzata
      list.sortableInstance = sortableInstance
    })
  }

  handleSort(evt) {
    const itemId = evt.item.dataset.id
    const newPosition = evt.newIndex + 1
    const newParentId = evt.to.dataset.parentId || null
    
    console.log("Handling sort:", { itemId, newPosition, newParentId, fromList: evt.from, toList: evt.to })
    
    // Rimuovi il placeholder se presente
    this.removePlaceholder(evt.to)
    
    this.updatePosition(itemId, newPosition, newParentId)
  }
  
  showAllDropZones() {
    console.log("Showing ALL drop zones with colors")
    
    // Trova tutte le liste che potrebbero ricevere drop
    const allDropZones = this.element.querySelectorAll('ul[data-sortable-target="list"]')
    
    allDropZones.forEach(zone => {
      const parentId = zone.dataset.parentId
      const isMainList = !parentId // Lista principale
      
      if (isMainList) {
        // Zona principale = stesso livello (blu)
        zone.classList.add('drop-zone-same-level', 'active')
      } else {
        // Zone annidate = indent (verde)
        zone.classList.add('drop-zone-indent', 'active')
      }
      
      zone.style.minHeight = '40px'
      zone.style.padding = '8px'
      
      // Mostra il placeholder se presente
      const placeholder = zone.querySelector('.drop-placeholder')
      if (placeholder) {
        placeholder.classList.remove('hidden')
        placeholder.style.display = 'block'
      }
    })
  }
  
  hideAllDropZones() {
    console.log("Hiding ALL drop zones")
    
    const allDropZones = this.element.querySelectorAll('ul[data-sortable-target="list"]')
    
    allDropZones.forEach(zone => {
      // Rimuovi tutte le classi di stile
      zone.classList.remove('drop-zone-same-level', 'drop-zone-indent', 'drop-zone-outdent', 'active')
      zone.style.minHeight = '30px'
      zone.style.padding = ''
      
      // Nascondi il placeholder se la lista è vuota (solo children reali)
      const realChildren = Array.from(zone.children).filter(child => 
        !child.classList.contains('drop-placeholder') && 
        !child.classList.contains('drag-indicator')
      )
      
      if (realChildren.length === 0) {
        const placeholder = zone.querySelector('.drop-placeholder')
        if (placeholder) {
          placeholder.classList.add('hidden')
          placeholder.style.display = 'none'
        }
      }
    })
  }
  
  cleanupPlaceholders(targetList) {
    // Rimuovi il placeholder se sono stati aggiunti elementi reali
    const realChildren = Array.from(targetList.children).filter(child => 
      !child.classList.contains('drop-placeholder')
    )
    
    if (realChildren.length > 0) {
      const placeholder = targetList.querySelector('.drop-placeholder')
      if (placeholder) {
        placeholder.remove()
      }
    }
  }
  
  removePlaceholder(list) {
    // Rimuovi il placeholder se un elemento è stato droppato in una lista vuota
    const placeholder = list.querySelector('.empty-placeholder')
    if (placeholder && list.children.length > 1) {
      placeholder.remove()
      list.classList.remove('empty-drop-zone')
    }
  }

  async updatePosition(itemId, position, parentId) {
    try {
      const response = await fetch(`/list_items/${itemId}/move`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken(),
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          position: position,
          parent_id: parentId
        })
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      console.log('Position updated successfully')
      
      // Aggiorna le frecce dinamicamente
      setTimeout(() => {
        this.updateCollapseButtons()
      }, 100)
      
    } catch (error) {
      console.error('Error updating position:', error)
      this.showError('Errore durante lo spostamento dell\'elemento')
    }
  }
  
  updateCollapseButtons() {
    // Trova tutti gli elementi li[data-id]
    const allItems = document.querySelectorAll('li[data-id]')
    
    allItems.forEach(item => {
      const itemId = item.dataset.id
      const hasChildren = item.querySelector('ul[data-parent-id="' + itemId + '"] li[data-id]') !== null
      const existingButton = item.querySelector('.collapse-btn')
      const spacer = item.querySelector('.collapse-spacer')
      
      if (hasChildren && !existingButton) {
        // Aggiungi freccia se ha children ma non ha la freccia
        this.addCollapseButton(item, itemId)
      } else if (!hasChildren && existingButton) {
        // Rimuovi freccia se non ha children ma ha la freccia
        this.removeCollapseButton(item)
      }
    })
  }
  
  addCollapseButton(item, itemId) {
    const spacer = item.querySelector('.collapse-spacer')
    if (!spacer) return
    
    const button = document.createElement('button')
    button.className = 'collapse-btn w-5 h-5 flex items-center justify-center text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded transition-colors'
    button.setAttribute('data-action', 'click->collapse#toggle')
    button.setAttribute('data-target-id', `children-${itemId}`)
    button.setAttribute('title', 'Espandi/Comprimi')
    
    button.innerHTML = `
      <svg class="w-4 h-4 transform transition-transform duration-200" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
      </svg>
    `
    
    spacer.replaceWith(button)
    
    // Crea il div collapsible-content se non esiste
    const existingContent = document.getElementById(`children-${itemId}`)
    if (!existingContent) {
      const childrenUl = item.querySelector(`ul[data-parent-id="${itemId}"]`)
      if (childrenUl && childrenUl.querySelector('li[data-id]')) {
        const wrapper = document.createElement('div')
        wrapper.id = `children-${itemId}`
        wrapper.className = 'collapsible-content ml-8 pb-2'
        
        // Sposta l'ul dentro il wrapper
        childrenUl.parentNode.insertBefore(wrapper, childrenUl)
        wrapper.appendChild(childrenUl)
      }
    }
  }
  
  removeCollapseButton(item) {
    const button = item.querySelector('.collapse-btn')
    if (!button) return
    
    const spacer = document.createElement('div')
    spacer.className = 'w-5 h-5 collapse-spacer'
    
    button.replaceWith(spacer)
  }
  
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.content : ''
  }
  
  showError(message) {
    alert(message)
  }
}
