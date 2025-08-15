import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scenesContainer", "sceneCounter"]
  static values = { sceneCount: Number }

  connect() {
    this.updateSceneCounter()
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
              <option value="avatar_001">Professional Male</option>
              <option value="avatar_002">Professional Female</option>
              <option value="avatar_003">Casual Male</option>
              <option value="avatar_004">Casual Female</option>
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
}