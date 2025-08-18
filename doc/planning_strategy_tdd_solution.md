# Planning Strategy - Solución TDD Completa

## 🎯 Problema Identificado

El flujo de generación de estrategia estaba fallando en:
1. **Datos no se almacenaban completamente** en `CreasStrategyPlan`
2. **Formato de respuesta incorrecto** del controlador JSON
3. **JavaScript básico** que no presentaba los datos reales
4. **Falta de tests** para verificar el flujo completo

## 🧪 Approach TDD Implementado

### 1. **Test First**: Definir comportamiento esperado
Creé `spec/controllers/creas_strategy_plans_controller_spec.rb` con tests que definen:
- ✅ Formato exacto esperado del JSON
- ✅ Estructura de semanas y días
- ✅ Manejo de datos faltantes/malformados
- ✅ Mapeo correcto de tipos de contenido

### 2. **Red**: Tests fallan inicialmente
Los tests revelaron que:
- ❌ El parser no entendía la estructura `content_pieces`
- ❌ Los días no se mapeaban correctamente (Monday → Mon)
- ❌ Los goals/themes no se extraían bien

### 3. **Green**: Implementar solución mínima
Corregí el controlador `CreasStrategyPlansController`:

```ruby
def extract_goal_from_week(week_data)
  week_data.dig("theme") || week_data.dig("goal") || fallback
end

def extract_days_from_week(week_data)
  content_pieces = week_data.dig("content_pieces") || []
  
  # Group content by day
  content_by_day = {}
  content_pieces.each do |piece|
    day_key = map_day_to_short_name(piece["day"])
    content_by_day[day_key] ||= []
    content_by_day[day_key] << piece["type"]
  end
  
  # Map to 7-day structure
  %w[Mon Tue Wed Thu Fri Sat Sun].map do |day|
    { day: day, contents: content_by_day[day] || [] }
  end
end

def map_day_to_short_name(day_name)
  { "Monday" => "Mon", "Tuesday" => "Tue", ... }[day_name.capitalize]
end
```

### 4. **Refactor**: Mejorar presentación visual
Implementé JavaScript completo en `app/javascript/planning_calendar.js`:

```javascript
function displayStrategyData(plan) {
  // Update page title
  if (plan.strategy_name) {
    document.querySelector('h1').textContent = plan.strategy_name;
  }
  
  // Update each week
  plan.weeks.forEach((weekData, index) => {
    updateWeekDisplay(weekData, index);
  });
}

function updateWeekDisplay(weekData, weekIndex) {
  const weekCard = document.querySelectorAll('.grid.gap-6 > .bg-card')[weekIndex];
  
  // Update goal
  updateWeekGoal(weekCard, weekData.goal);
  
  // Update days content
  updateWeekDays(weekCard, weekData.days);
}

function createContentElement(contentType) {
  // Create visual content blocks with:
  // - Correct colors (Post=blue, Reel=purple, Live=orange)
  // - Proper icons (Instagram, Video, Radio)
  // - Responsive styling
}
```

## 📊 Estructura de Datos Verificada

### Input (OpenAI Service Response)
```json
{
  "strategy_name": "Monthly Strategy",
  "weekly_plan": [
    {
      "week_number": 1,
      "theme": "Awareness", 
      "content_pieces": [
        {
          "day": "Monday",
          "type": "Post",
          "platform": "instagram",
          "topic": "Brand introduction"
        },
        {
          "day": "Wednesday", 
          "type": "Reel",
          "platform": "instagram"
        }
      ]
    }
  ]
}
```

### Storage (CreasStrategyPlan.weekly_plan)
```json
[
  {
    "week_number": 1,
    "theme": "Awareness",
    "content_pieces": [
      {"day": "Monday", "type": "Post"},
      {"day": "Wednesday", "type": "Reel"}
    ]
  }
]
```

### Output (Frontend JSON API)
```json
{
  "id": "uuid",
  "strategy_name": "Monthly Strategy",
  "weeks": [
    {
      "week_number": 1,
      "goal": "Awareness",
      "days": [
        {"day": "Mon", "contents": ["Post"]},
        {"day": "Tue", "contents": []},
        {"day": "Wed", "contents": ["Reel"]},
        {"day": "Thu", "contents": []},
        {"day": "Fri", "contents": []},
        {"day": "Sat", "contents": []},
        {"day": "Sun", "contents": []}
      ]
    }
  ]
}
```

## ✅ Tests de Verificación

### Test del Controlador
```ruby
# spec/controllers/creas_strategy_plans_controller_spec.rb
it 'formats plan data correctly for frontend consumption' do
  result = controller.send(:format_plan_for_frontend, sample_plan)
  
  expect(result[:weeks][0][:days].find { |d| d[:day] == 'Mon' })
    .to eq({ day: 'Mon', contents: ['Post'] })
    
  expect(result[:weeks][0][:days].find { |d| d[:day] == 'Wed' })
    .to eq({ day: 'Wed', contents: ['Reel'] })
end
```

### Test de Integración Completa
```ruby
# spec/requests/planning_strategy_integration_spec.rb
it 'creates complete strategy and displays structured calendar data' do
  post creas_strategist_index_path, params: { month: "2024-01" }
  
  plan_id = response.location.match(/plan_id=([^&]+)/)[1]
  created_plan = CreasStrategyPlan.find(plan_id)
  
  # Verify storage
  expect(created_plan.weekly_plan[0]['content_pieces']).to include(
    hash_including('day' => 'Monday', 'type' => 'Post')
  )
  
  # Verify API response
  get creas_strategy_plan_path(created_plan.id)
  json_response = JSON.parse(response.body)
  
  expect(json_response['weeks'][0]['days'].find { |d| d['day'] == 'Mon' })
    .to include('contents' => ['Post'])
end
```

## 🚀 Flujo Final Verificado

1. **Usuario hace clic** en "Add Content Plan"
2. **POST** a `/creas_strategist` → genera plan con OpenAI
3. **Almacenamiento** completo en `CreasStrategyPlan.weekly_plan`
4. **Redirect** a `/planning?plan_id=<uuid>`
5. **JavaScript** detecta `plan_id` automáticamente
6. **GET** `/creas_strategy_plans/:id` → JSON formateado
7. **Hidratación visual** completa del calendario

## 🔧 Archivos Modificados

### Backend
- `app/controllers/creas_strategy_plans_controller.rb` - Parser mejorado
- `spec/controllers/creas_strategy_plans_controller_spec.rb` - Tests TDD

### Frontend  
- `app/javascript/planning_calendar.js` - JavaScript completo
- `app/views/plannings/show.haml` - Include del JavaScript

### Documentación
- `spec/requests/planning_strategy_integration_spec.rb` - Test de integración completa

## 🧪 Cómo Probar

### 1. Tests Unitarios
```bash
rspec spec/controllers/creas_strategy_plans_controller_spec.rb
```

### 2. Test Manual
1. Visitar `http://localhost:3000/planning`
2. Clic en "Add Content Plan"
3. Verificar redirect con `plan_id`
4. Abrir Dev Tools → Console
5. Verificar logs: "Strategy plan loaded: X weeks"
6. Verificar calendario se actualiza con contenido real

### 3. Verificación de Datos
```bash
rails console
plan = CreasStrategyPlan.last
puts plan.weekly_plan.to_json
# Debe mostrar estructura completa con content_pieces
```

## ✅ Resultado Final

- ✅ **Datos se almacenan completamente** en base de datos
- ✅ **JSON API retorna formato correcto** para frontend  
- ✅ **JavaScript presenta datos reales** dinámicamente
- ✅ **Tests cubren flujo completo** end-to-end
- ✅ **Logs claros** para debugging
- ✅ **Manejo de errores** gracioso

**La estrategia ahora se genera, almacena y presenta correctamente siguiendo TDD** 🎯