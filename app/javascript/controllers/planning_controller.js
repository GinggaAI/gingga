import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Using direct DOM queries instead of targets for more reliable functionality
  static values = { 
    currentMonth: String,
    currentPlan: Object
  }

  connect() {
    this.initialize()
  }

  initialize() {
    this.setupEventListeners()
    this.updateButtonText()
    this.updateOverviewButton()
    
    // Parse and handle current plan if it exists and is not null
    if (this.currentPlanValue && this.currentPlanValue !== null && this.currentPlanValue !== 'null') {
      let plan = this.currentPlanValue
      // If it's a string, try to parse it
      if (typeof plan === 'string') {
        try {
          plan = JSON.parse(plan)
        } catch (e) {
          console.warn('Failed to parse current plan JSON:', e)
          return
        }
      }
      
      if (plan && plan.weekly_plan) {
        this.populateCalendarWithStrategy(plan)
        this.updateVoxaButton()
      }
    }
  }

  setupEventListeners() {
    const toggleBtn = document.getElementById('toggle-form')
    const overviewBtn = document.getElementById('toggle-overview')
    const cancelBtn = document.getElementById('cancel-form')
    const form = document.getElementById('strategy-creation-form')

    if (toggleBtn && form) {
      toggleBtn.addEventListener('click', (e) => {
        e.preventDefault()
        const isFormVisible = form.style.display !== 'none'
        form.style.display = isFormVisible ? 'none' : 'block'
        this.resetForm()
        this.hideMessages()
      })
    }

    if (overviewBtn) {
      overviewBtn.addEventListener('click', (e) => {
        e.preventDefault()
        const resultDiv = document.getElementById('strategy-result')
        if (resultDiv) {
          const isResultVisible = resultDiv.style.display !== 'none'
          resultDiv.style.display = isResultVisible ? 'none' : 'block'
        }
      })
    }

    if (cancelBtn && form) {
      cancelBtn.addEventListener('click', (e) => {
        e.preventDefault()
        form.style.display = 'none'
        this.resetForm()
      })
    }

    // Form submission
    if (form) {
      form.addEventListener('submit', (e) => this.handleFormSubmit(e))
    }

    this.setupResourcesOverrideHandlers()
  }

  hideStrategyOverview() {
    const resultDiv = document.getElementById('strategy-result')
    if (resultDiv) {
      resultDiv.style.display = 'none'
    }
  }

  showContentDetails(weekIndex, contentPiece) {
    const weekDetailsId = `week-details-${weekIndex}`
    let weekDetails = document.getElementById(weekDetailsId)
    
    if (!weekDetails) {
      weekDetails = document.createElement('div')
      weekDetails.id = weekDetailsId
      weekDetails.className = 'bg-gray-50 border border-gray-200 rounded-lg p-4 mt-3'
      weekDetails.innerHTML = `
        <div class="flex justify-between items-center mb-3">
          <div class="text-lg font-semibold text-gray-700">📋 Week ${weekIndex + 1} Details</div>
          <button data-action="click->planning#hideContentDetails" data-planning-week-id="${weekDetailsId}" class="text-gray-500 hover:text-gray-700 text-xl">&times;</button>
        </div>
        <div class="content-details-grid grid grid-cols-1 gap-3"></div>
      `
      
      const weekElements = document.querySelectorAll('.space-y-6 > .bg-card.text-card-foreground.border-0.shadow-lg.rounded-2xl')
      if (weekElements[weekIndex]) {
        weekElements[weekIndex].appendChild(weekDetails)
      }
    }

    weekDetails.style.display = 'block'
    
    const detailsGrid = weekDetails.querySelector('.content-details-grid')
    if (detailsGrid) {
      const contentId = `content-detail-${Date.now()}`
      const platform = contentPiece.platform || 'Instagram'
      const type = contentPiece.content_type || 'Reel'
      
      const contentDetail = document.createElement('div')
      contentDetail.id = contentId
      contentDetail.className = 'bg-white border border-gray-200 rounded-lg p-3'
      contentDetail.innerHTML = `
        <div class="space-y-2">
          <div class="flex justify-between items-start">
            <div class="font-medium text-gray-800">${contentPiece.title || contentPiece.content_title || 'Untitled Content'}</div>
            <button data-action="click->planning#removeContentDetail" data-planning-content-id="${contentId}" class="text-gray-400 hover:text-gray-600 text-lg font-bold">&times;</button>
          </div>
          <div class="text-sm text-gray-600">${contentPiece.description || contentPiece.content_description || 'No description available'}</div>
          <div class="flex gap-2">
            <span class="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded">${platform} ${type}</span>
          </div>
        </div>
      `
      
      detailsGrid.appendChild(contentDetail)
    }
  }

  hideContentDetails(event) {
    const weekDetailsId = event.params.weekId
    const weekDetails = document.getElementById(weekDetailsId)
    if (weekDetails) {
      weekDetails.style.display = 'none'
    }
  }

  removeContentDetail(event) {
    const contentId = event.params.contentId
    const contentDetail = document.getElementById(contentId)
    if (contentDetail) {
      contentDetail.remove()
    }
  }

  handleFormSubmit(e) {
    e.preventDefault()
    const form = e.target
    const formData = new FormData(form)
    
    this.setLoadingState(true)
    
    fetch(form.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').getAttribute('content')
      }
    })
    .then(response => response.json())
    .then(data => {
      this.setLoadingState(false)
      if (data.success) {
        this.currentPlanValue = data.plan
        this.displayStrategyResult(data.plan, true)
        form.style.display = 'none'
        this.updateButtonText()
        this.updateOverviewButton()
        this.populateCalendarWithStrategy(data.plan)
        this.updateVoxaButton()
      } else {
        this.showError(data.error || 'An error occurred while creating the strategy.')
      }
    })
    .catch(error => {
      this.setLoadingState(false)
      this.showError('Network error. Please try again.')
    })
  }

  setLoadingState(loading) {
    const submitButton = document.getElementById('submit-strategy')
    const submitText = document.querySelector('#submit-strategy .submit-text')
    const loadingSpinner = document.querySelector('#submit-strategy .loading-spinner')
    
    if (submitButton) {
      submitButton.disabled = loading
    }
    if (submitText) {
      submitText.style.display = loading ? 'none' : 'inline'
    }
    if (loadingSpinner) {
      loadingSpinner.style.display = loading ? 'inline' : 'none'
    }
  }

  displayStrategyResult(plan, shouldShow = false) {
    const strategyResult = document.getElementById('strategy-result')
    if (!strategyResult || !plan) return
    
    strategyResult.style.display = shouldShow ? 'block' : 'none'
  }

  showError(message) {
    const errorMessage = document.getElementById('error-message')
    const errorText = document.getElementById('error-text')
    if (errorMessage && errorText) {
      errorText.textContent = message
      errorMessage.style.display = 'block'
    }
  }

  hideMessages() {
    const strategyResult = document.getElementById('strategy-result')
    const errorMessage = document.getElementById('error-message')
    if (strategyResult) {
      strategyResult.style.display = 'none'
    }
    if (errorMessage) {
      errorMessage.style.display = 'none'
    }
  }

  resetForm() {
    const form = document.getElementById('strategy-creation-form')
    if (form) {
      const inputs = form.querySelectorAll('input:not([name="month"]), textarea, select')
      inputs.forEach(input => {
        if (input.type === 'checkbox' || input.type === 'radio') {
          input.checked = false
        } else {
          input.value = ''
        }
      })
    }
  }

  updateButtonText() {
    const buttonText = document.getElementById('button-text')
    if (buttonText && this.currentPlanValue) {
      buttonText.textContent = 'Add New Content'
    }
  }

  updateOverviewButton() {
    const toggleOverview = document.getElementById('toggle-overview')
    if (toggleOverview) {
      toggleOverview.style.display = 'block'
    }
  }

  populateCalendarWithStrategy(plan) {
    if (!plan || !plan.weekly_plan) return
    
    // Clear existing content first
    const weekElements = document.querySelectorAll('.space-y-6 > .bg-card.text-card-foreground.border-0.shadow-lg.rounded-2xl')
    weekElements.forEach(weekElement => {
      const dayColumns = weekElement.querySelectorAll('.grid-cols-7 > div')
      dayColumns.forEach(dayElement => {
        const existingContent = dayElement.querySelectorAll('.bg-blue-50.border.border-blue-200')
        existingContent.forEach(content => content.remove())
      })
    })

    // Add new content
    plan.weekly_plan.forEach((week, weekIndex) => {
      if (week.content_pieces) {
        week.content_pieces.forEach(piece => {
          const dayIndex = this.getDayIndexFromPiece(piece)
          if (dayIndex !== -1) {
            this.addContentToCalendar(weekIndex, dayIndex, piece)
          }
        })
      }
    })
  }

  getDayIndexFromPiece(piece) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    let dayName = piece.day || piece.scheduled_day || piece.publish_day
    
    if (typeof dayName === 'string') {
      dayName = dayName.charAt(0).toUpperCase() + dayName.slice(1).toLowerCase()
    }
    
    return days.indexOf(dayName)
  }

  addContentToCalendar(weekIndex, dayIndex, contentPiece) {
    const weekElements = document.querySelectorAll('.space-y-6 > .bg-card.text-card-foreground.border-0.shadow-lg.rounded-2xl')
    
    if (weekIndex < weekElements.length) {
      const weekElement = weekElements[weekIndex]
      const dayColumns = weekElement.querySelectorAll('.grid-cols-7 > div')
      
      if (dayIndex < dayColumns.length) {
        const dayElement = dayColumns[dayIndex]
        const contentDiv = document.createElement('div')
        
        const title = contentPiece.title || contentPiece.content_title || 'Content'
        const platform = contentPiece.platform || 'Instagram'
        const icon = this.getContentIcon(platform, contentPiece.content_type)
        
        contentDiv.className = 'bg-blue-50 border border-blue-200 rounded-lg p-2 text-xs cursor-pointer hover:bg-blue-100 transition-colors'
        contentDiv.innerHTML = `<div class="font-medium">${icon} ${title.substring(0, 20)}${title.length > 20 ? '...' : ''}</div>`
        contentDiv.title = title
        contentDiv.addEventListener('click', () => this.showContentDetails(weekIndex, contentPiece))
        
        const addButton = dayElement.querySelector('button')
        if (addButton) {
          dayElement.insertBefore(contentDiv, addButton)
        } else {
          dayElement.appendChild(contentDiv)
        }
      }
    }
  }

  getContentIcon(platform, contentType) {
    const platformIcons = {
      'Instagram': '📸',
      'TikTok': '🎵',
      'YouTube': '🎥',
      'Facebook': '👥',
      'Twitter': '🐦',
      'LinkedIn': '💼'
    }
    return platformIcons[platform] || '📱'
  }

  setupResourcesOverrideHandlers() {
    const selects = ['budget-select', 'team-size-select', 'tools-select']
    selects.forEach(selectId => {
      const select = document.getElementById(selectId)
      if (select) {
        select.addEventListener('change', () => this.updateResourcesOverrideJSON())
      }
    })
  }

  updateResourcesOverrideJSON() {
    const budgetSelect = document.getElementById('budget-select')
    const teamSizeSelect = document.getElementById('team-size-select')
    const toolsSelect = document.getElementById('tools-select')
    const hiddenInput = document.getElementById('resources-override-json')
    
    if (hiddenInput) {
      const resourcesOverride = {
        budget: budgetSelect?.value || null,
        team_size: teamSizeSelect?.value || null,
        tools: toolsSelect?.value || null
      }
      
      hiddenInput.value = JSON.stringify(resourcesOverride)
    }
  }

  updateVoxaButton() {
    const voxaBtn = document.getElementById('voxa-refine')
    if (voxaBtn) {
      if (this.currentPlanValue && this.currentPlanValue.id) {
        voxaBtn.style.display = 'block'
        voxaBtn.addEventListener('click', (e) => this.handleVoxaRefine(e))
      } else {
        voxaBtn.style.display = 'none'
      }
    }
  }

  handleVoxaRefine(e) {
    e.preventDefault()
    if (!this.currentPlanValue || !this.currentPlanValue.id) {
      this.showError('No strategy plan available for refinement.')
      return
    }
    
    // Implementation for Voxa refinement
    console.log('Voxa refine clicked for plan:', this.currentPlanValue.id)
  }
}