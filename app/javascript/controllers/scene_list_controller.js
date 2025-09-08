import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scenesContainer", "sceneCounter", "aiToggle", "scene", "avatarFields", "videoTypeSelect"]
  static values = { sceneCount: Number, avatars: Array }

  connect() {
    this.updateSceneCounter()
    this.initializeAvatarToggle()
  }

  initializeAvatarToggle() {
    // Set initial state based on checkbox value
    this.toggleAvatarFields()
  }

  toggleAiAvatars() {
    this.toggleAvatarFields()
  }

  toggleAvatarFields() {
    const isEnabled = this.aiToggleTarget.checked
    const avatarFieldsTargets = this.avatarFieldsTargets
    const videoTypeSelects = this.videoTypeSelectTargets
    
    // Handle avatar fields visibility
    avatarFieldsTargets.forEach(fields => {
      if (isEnabled) {
        fields.style.display = 'grid'
        fields.classList.remove('opacity-50')
        // Enable all inputs
        const inputs = fields.querySelectorAll('input, select')
        inputs.forEach(input => input.disabled = false)
      } else {
        fields.style.display = 'none'
        fields.classList.add('opacity-50')
        // Disable all inputs
        const inputs = fields.querySelectorAll('input, select')
        inputs.forEach(input => input.disabled = true)
      }
    })
    
    // Handle video type select states
    videoTypeSelects.forEach(select => {
      if (isEnabled) {
        // When AI Avatar is enabled, enable select and default to avatar
        select.disabled = false
        select.value = 'avatar'
      } else {
        // When AI Avatar is disabled, disable select and force to kling
        select.disabled = true
        select.value = 'kling'
      }
    })
    
    // Also update avatar fields visibility based on select changes
    this.updateAvatarFieldsVisibility()
  }

  updateAvatarFieldsVisibility() {
    const videoTypeSelects = this.videoTypeSelectTargets
    const avatarFieldsTargets = this.avatarFieldsTargets
    
    videoTypeSelects.forEach((select, index) => {
      const avatarFields = avatarFieldsTargets[index]
      if (avatarFields) {
        if (select.value === 'avatar') {
          avatarFields.style.display = 'grid'
          avatarFields.style.opacity = '1'
        } else {
          avatarFields.style.display = 'none'
          avatarFields.style.opacity = '0.5'
        }
      }
    })
  }

  handleVideoTypeChange(event) {
    this.updateAvatarFieldsVisibility()
  }

  addScene() {
    if (this.sceneCountValue >= 5) {
      alert("Maximum of 5 scenes allowed")
      return
    }

    this.sceneCountValue++
    this.createSceneElement()
    this.updateSceneCounter()
  }

  removeScene(event) {
    if (this.sceneCountValue <= 1) {
      alert("At least 1 scene is required")
      return
    }

    const sceneElement = event.target.closest('[data-scene-number]')
    if (sceneElement) {
      sceneElement.remove()
      this.sceneCountValue--
      this.renumberScenes()
      this.updateSceneCounter()
    }
  }

  createSceneElement() {
    const sceneNumber = this.sceneCountValue
    const sceneHTML = this.generateSceneHTML(sceneNumber)
    
    this.scenesContainerTarget.insertAdjacentHTML('beforeend', sceneHTML)
  }

  generateSceneHTML(sceneNumber) {
    const avatarOptions = this.generateAvatarOptions();
    
    return `
      <div class="ui-scene-fields" data-scene-number="${sceneNumber}">
        <div class="ui-scene-fields__header">
          <h4 class="ui-scene-fields__title">Scene ${sceneNumber}</h4>
          ${sceneNumber > 1 ? `
            <button type="button" 
                    class="ui-scene-fields__remove" 
                    data-action="click->scene-list#removeScene"
                    aria-label="Remove Scene ${sceneNumber}">
              Remove Scene
            </button>
          ` : ''}
        </div>
        <div class="ui-scene-fields__content">
          <input type="hidden" name="reel[scenes][${sceneNumber}][scene_number]" value="${sceneNumber}">
          
          <div class="ui-scene-fields__field">
            <label class="ui-scene-fields__label">AI Avatar</label>
            <select name="reel[scenes][${sceneNumber}][avatar_id]" 
                    class="ui-scene-fields__select"
                    aria-describedby="avatar_help_${sceneNumber}">
              <option value="">Select Avatar</option>
              ${avatarOptions}
            </select>
            <small id="avatar_help_${sceneNumber}" class="ui-scene-fields__help">
              Choose the AI avatar for this scene
            </small>
          </div>
          
          <div class="ui-scene-fields__field">
            <label class="ui-scene-fields__label">Voice</label>
            <select name="reel[scenes][${sceneNumber}][voice_id]" 
                    class="ui-scene-fields__select"
                    aria-describedby="voice_help_${sceneNumber}">
              <option value="">Select Voice</option>
              <option value="voice_001">Clear Male Voice</option>
              <option value="voice_002">Clear Female Voice</option>
              <option value="voice_003">Friendly Male Voice</option>
              <option value="voice_004">Friendly Female Voice</option>
            </select>
            <small id="voice_help_${sceneNumber}" class="ui-scene-fields__help">
              Choose the voice for this scene
            </small>
          </div>
          
          <div class="ui-scene-fields__field">
            <label class="ui-scene-fields__label">Script</label>
            <textarea name="reel[scenes][${sceneNumber}][script]"
                     placeholder="Enter the script for Scene ${sceneNumber}. What should the avatar say in this scene?"
                     class="ui-scene-fields__textarea"
                     rows="4"
                     maxlength="500"
                     aria-describedby="script_help_${sceneNumber}"
                     data-controller="scene-character-counter"
                     data-action="input->scene-character-counter#updateCounter"></textarea>
            <div class="ui-scene-fields__field-footer">
              <small id="script_help_${sceneNumber}" class="ui-scene-fields__help">
                Keep it under 500 characters for best results
              </small>
              <span class="ui-scene-fields__char-count" data-scene-character-counter-target="counter">
                0/500
              </span>
            </div>
          </div>
        </div>
      </div>
    `
  }

  renumberScenes() {
    const sceneElements = this.scenesContainerTarget.querySelectorAll('[data-scene-number]')
    
    sceneElements.forEach((element, index) => {
      const newSceneNumber = index + 1
      element.setAttribute('data-scene-number', newSceneNumber)
      
      // Update scene title
      const title = element.querySelector('.ui-scene-fields__title')
      if (title) title.textContent = `Scene ${newSceneNumber}`
      
      // Update form field names and IDs
      this.updateSceneFormFields(element, newSceneNumber)
    })
  }

  updateSceneFormFields(sceneElement, sceneNumber) {
    // Update hidden scene number input
    const hiddenInput = sceneElement.querySelector('input[type="hidden"]')
    if (hiddenInput) {
      hiddenInput.name = `reel[scenes][${sceneNumber}][scene_number]`
      hiddenInput.value = sceneNumber
    }
    
    // Update all form inputs
    const inputs = sceneElement.querySelectorAll('input, select, textarea')
    inputs.forEach(input => {
      if (input.name && input.name.includes('[scenes][')) {
        input.name = input.name.replace(/\[scenes\]\[\d+\]/, `[scenes][${sceneNumber}]`)
      }
    })
    
    // Update IDs and aria-describedby attributes
    const elementsWithIds = sceneElement.querySelectorAll('[id*="_"], [aria-describedby*="_"]')
    elementsWithIds.forEach(element => {
      if (element.id) {
        element.id = element.id.replace(/_\d+$/, `_${sceneNumber}`)
      }
      if (element.getAttribute('aria-describedby')) {
        const describedBy = element.getAttribute('aria-describedby')
        element.setAttribute('aria-describedby', describedBy.replace(/_\d+$/, `_${sceneNumber}`))
      }
    })
  }

  updateSceneCounter() {
    this.sceneCounterTarget.textContent = this.sceneCountValue
  }

  generateAvatarOptions() {
    if (!this.hasAvatarsValue || this.avatarsValue.length === 0) {
      return '<option value="" disabled>No avatars available. Please sync your avatars from your provider first.</option>';
    }
    
    return this.avatarsValue.map(avatar => {
      const [name, id] = avatar;
      return `<option value="${id}">${name}</option>`;
    }).join('');
  }
}