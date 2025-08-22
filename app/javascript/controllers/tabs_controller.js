import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    if (this.tabTargets.length === 0) {
      return
    }
    
    if (this.panelTargets.length === 0) {
      return
    }
    
    // Initialize all panels as hidden first
    this.panelTargets.forEach((panel, index) => {
      panel.setAttribute('hidden', '')
    })
    
    // Find and activate the tab marked as active, or activate first tab
    const activeTab = this.tabTargets.find(tab => tab.dataset.state === "active")
    if (activeTab) {
      this.activateTab(activeTab)
    } else if (this.tabTargets.length > 0) {
      this.activateTab(this.tabTargets[0])
    }
  }

  switchTab(event) {
    event.preventDefault()
    const clickedTab = event.currentTarget
    this.activateTab(clickedTab)
  }

  activateTab(activeTab) {
    // Deactivate all tabs and panels
    this.tabTargets.forEach(tab => {
      tab.dataset.state = "inactive"
      tab.setAttribute("aria-selected", "false")
    })

    this.panelTargets.forEach(panel => {
      panel.dataset.state = "inactive"
      panel.setAttribute('hidden', '')
    })

    // Activate the clicked tab
    activeTab.dataset.state = "active"
    activeTab.setAttribute("aria-selected", "true")

    // Find corresponding panel using aria-controls
    const panelId = activeTab.getAttribute("aria-controls")
    
    // Find panel in our targets instead of using document.getElementById
    const activePanel = this.panelTargets.find(panel => panel.id === panelId)
    if (activePanel) {
      activePanel.dataset.state = "active"
      activePanel.removeAttribute('hidden')
    }
  }
}