document.addEventListener('DOMContentLoaded', function() {
  const urlParams = new URLSearchParams(window.location.search);
  const planId = urlParams.get('plan_id');
  
  if (planId) {
    fetchAndDisplayStrategy(planId);
  }

  // Form functionality is handled by inline JavaScript in the view
  // No need to initialize form functionality here anymore
});


function fetchAndDisplayStrategy(planId) {
  fetch(`/creas_strategy_plans/${planId}`)
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      return response.json();
    })
    .then(plan => {
      displayStrategyData(plan);
    })
    .catch(error => {
      showErrorMessage('Failed to load strategy plan. Please try again.');
    });
}

function displayStrategyData(plan) {
  if (!plan || !plan.weeks) {
    return;
  }

  // Update page title if strategy name exists
  if (plan.strategy_name) {
    const titleElement = document.querySelector('h1');
    if (titleElement) {
      titleElement.textContent = plan.strategy_name;
    }
  }

  // Update each week
  plan.weeks.forEach((weekData, index) => {
    updateWeekDisplay(weekData, index);
  });

  // Show success message
  showSuccessMessage(`Strategy plan loaded: ${plan.weeks.length} weeks`);
}

function updateWeekDisplay(weekData, weekIndex) {
  // Find the week container (skip the header card)
  const weekCards = document.querySelectorAll('.grid.gap-6 > .bg-card');
  const weekCard = weekCards[weekIndex];
  
  if (!weekCard) {
    return;
  }

  // Update goal dropdown
  updateWeekGoal(weekCard, weekData.goal);
  
  // Update day content
  updateWeekDays(weekCard, weekData.days);
}

function updateWeekGoal(weekCard, goal) {
  if (!goal) return;
  
  const goalSpan = weekCard.querySelector('span[style*="pointer-events"]');
  if (goalSpan) {
    goalSpan.textContent = goal;
  }
}

function updateWeekDays(weekCard, daysData) {
  if (!daysData || !Array.isArray(daysData)) return;

  const dayColumns = weekCard.querySelectorAll('.space-y-2');
  
  daysData.forEach((dayData, dayIndex) => {
    if (dayColumns[dayIndex] && dayData.contents && dayData.contents.length > 0) {
      updateDayContent(dayColumns[dayIndex], dayData);
    }
  });
}

function updateDayContent(dayColumn, dayData) {
  const dayContainer = dayColumn.querySelector('.bg-gray-50');
  if (!dayContainer) return;

  // Clear existing dynamic content (keep + button)
  const existingContent = dayContainer.querySelectorAll('.p-2.rounded-lg:not(.add-button)');
  existingContent.forEach(content => content.remove());

  // Add new content
  dayData.contents.forEach(contentType => {
    const contentElement = createContentElement(contentType);
    
    // Insert before the + button
    const addButton = dayContainer.querySelector('button');
    if (addButton) {
      dayContainer.insertBefore(contentElement, addButton);
    } else {
      dayContainer.appendChild(contentElement);
    }
  });
}

function createContentElement(contentType) {
  const contentDiv = document.createElement('div');
  contentDiv.className = 'p-2 rounded-lg text-white text-xs flex items-center gap-2';
  
  // Set background color based on content type
  const colors = {
    'post': '#3AC8FF',
    'reel': '#A37FFF', 
    'live': '#FF6848'
  };
  
  const bgColor = colors[contentType.toLowerCase()] || '#3AC8FF';
  contentDiv.style.backgroundColor = bgColor;
  
  // Create icon
  const icon = createContentIcon(contentType);
  contentDiv.appendChild(icon);
  
  // Create text
  const textSpan = document.createElement('span');
  textSpan.className = 'capitalize';
  textSpan.textContent = contentType.toLowerCase();
  contentDiv.appendChild(textSpan);
  
  return contentDiv;
}

function createContentIcon(contentType) {
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('class', 'lucide w-4 h-4');
  svg.setAttribute('fill', 'none');
  svg.setAttribute('height', '24');
  svg.setAttribute('stroke', 'currentColor');
  svg.setAttribute('stroke-linecap', 'round');
  svg.setAttribute('stroke-linejoin', 'round');
  svg.setAttribute('stroke-width', '2');
  svg.setAttribute('viewBox', '0 0 24 24');
  svg.setAttribute('width', '24');
  
  let iconPath = '';
  
  switch(contentType.toLowerCase()) {
    case 'reel':
      svg.classList.add('lucide-video');
      iconPath = '<path d="m16 13 5.223 3.482a.5.5 0 0 0 .777-.416V7.87a.5.5 0 0 0-.752-.432L16 10.5"></path><rect height="12" rx="2" width="14" x="2" y="6"></rect>';
      break;
    case 'live':
      svg.classList.add('lucide-radio');
      iconPath = '<path d="M4.9 19.1C1 15.2 1 8.8 4.9 4.9"></path><path d="M7.8 16.2c-2.3-2.3-2.3-6.1 0-8.5"></path><circle cx="12" cy="12" r="2"></circle><path d="M16.2 7.8c2.3 2.3 2.3 6.1 0 8.5"></path><path d="M19.1 4.9C23 8.8 23 15.1 19.1 19"></path>';
      break;
    default: // post
      svg.classList.add('lucide-instagram');
      iconPath = '<rect height="20" rx="5" ry="5" width="20" x="2" y="2"></rect><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"></path><line x1="17.5" x2="17.51" y1="6.5" y2="6.5"></line>';
  }
  
  svg.innerHTML = iconPath;
  return svg;
}

function showSuccessMessage(message) {
  // Could add toast notification here
}

function showErrorMessage(message) {
  // Could add error toast notification here
}