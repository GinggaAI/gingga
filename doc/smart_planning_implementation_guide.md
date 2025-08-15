# Smart Planning Implementation Guide

## 🎯 Descripción General

Esta implementación integra el flujo de generación de estrategia usando GPT (CreasStrategist) en la vista `/smart-planning`, creando un calendario visual por semana con contenido automatizado basado en la marca del usuario.

## 🏗️ Arquitectura Implementada

### Componentes Principales

1. **Vista Smart Planning** (`/app/views/plannings/smart_planning.html.erb`)
2. **CreasStrategistController** - Maneja la generación de planes
3. **CreasStrategyPlansController** - Sirve los planes generados
4. **JavaScript Frontend** - Hidrata la interfaz con datos del plan
5. **Modelo CreasStrategyPlan** - Persiste los planes en base de datos

## 📋 Flujo POST-Redirect-GET Implementado

### Paso 1: Clic en "New Content Plan"
```html
<%= form_with url: creas_strategist_index_path, method: :post, local: true do |form| %>
  <%= form.hidden_field :month, value: Date.current.strftime("%Y-%m") %>
  <%= form.submit "+ New Content Plan", class: "btn-primary" %>
<% end %>
```

### Paso 2: POST a /creas_strategist
```ruby
def create
  brand = current_user.brands.first
  # Genera estrategia con OpenAI
  plan = Creas::NoctuaStrategyService.new(
    user: current_user, 
    brief: brief, 
    brand: brand, 
    month: month
  ).call
  
  # Redirect con plan_id
  redirect_to smart_planning_path(plan_id: plan.id), status: :see_other
end
```

### Paso 3: Redirect a /smart-planning?plan_id=<uuid>
- El navegador automáticamente redirige a la URL con el `plan_id`
- La página se carga con JavaScript que detecta el parámetro

### Paso 4: JavaScript Fetch
```javascript
const planId = urlParams.get('plan_id');
if (planId) {
  fetchStrategyPlan(planId);
}

function fetchStrategyPlan(planId) {
  fetch(`/creas_strategy_plans/${planId}`)
    .then(response => response.json())
    .then(plan => hydrateCalendarView(plan));
}
```

### Paso 5: GET /creas_strategy_plans/:id
```ruby
def show
  plan = current_user.brands.joins(:creas_strategy_plans)
    .find_by(creas_strategy_plans: { id: params[:id] })
    &.creas_strategy_plans&.find(params[:id])
    
  render json: format_plan_for_frontend(plan)
end
```

### Paso 6: Hidratación de la UI
El JavaScript actualiza las cards de semana con datos reales:
- Badges de objetivo (Awareness, Engagement, Launch, Conversion)
- Conteo de contenido
- Tipos de contenido (Post, Reel, Live)

## 🛠️ Archivos Modificados/Creados

### Rutas Agregadas
```ruby
# config/routes.rb
resources :creas_strategist, only: [:create]
resources :creas_strategy_plans, only: [:show]
```

### Controladores
- `app/controllers/creas_strategist_controller.rb` - Actualizado para redirect
- `app/controllers/creas_strategy_plans_controller.rb` - Nuevo controlador

### Vistas
- `app/views/plannings/smart_planning.html.erb` - Actualizada con diseño de cards y JavaScript

### Estilos
- `app/assets/stylesheets/tokens.css` - Nuevos colores para sidebar
- `app/assets/stylesheets/utilities.css` - Botón CTA con gradiente

## 🧪 Cómo Probar la Implementación

### 1. Requisitos Previos
```bash
# Asegurar que el usuario tenga una marca
rails console
user = User.first
brand = user.brands.create!(
  name: "Test Brand",
  slug: "test-brand",
  industry: "technology",
  voice: "professional"
)
```

### 2. Probar el Flujo Completo
1. Visitar `/smart-planning`
2. Hacer clic en "+ New Content Plan"
3. Verificar redirect a `/smart-planning?plan_id=<id>`
4. Verificar que JavaScript actualice las cards con datos reales

### 3. Ejecutar Tests
```bash
# Tests específicos del flujo
rspec spec/requests/smart_planning_integration_spec.rb

# Tests del controlador original
rspec spec/requests/creas_strategist_spec.rb
```

## 🐛 Troubleshooting

### Problema: "Please create a brand profile first"
**Solución**: El usuario necesita una marca asociada
```ruby
current_user.brands.create!(name: "My Brand", slug: "my-brand")
```

### Problema: Error 500 en POST
**Verificar**:
- Token de OpenAI configurado
- Servicios `NoctuaBriefAssembler` y `Creas::NoctuaStrategyService` funcionales
- Conexión a base de datos

### Problema: JavaScript no hidrata la UI
**Verificar**:
- Plan_id presente en URL
- Endpoint `/creas_strategy_plans/:id` retorna JSON válido
- Console del navegador para errores de JavaScript

## 📊 Estructura de Datos Esperada

### Frontend espera este formato:
```typescript
type Week = {
  week_number: number;
  goal: "Awareness" | "Engagement" | "Launch" | "Conversion";
  days: {
    day: "Mon" | "Tue" | ...;
    contents: Array<"Post" | "Reel" | "Live">;
  }[];
}

type Plan = {
  id: string;
  strategy_name: string;
  weeks: Week[];
}
```

### Base de datos almacena:
```ruby
# CreasStrategyPlan
{
  weekly_plan: [
    {
      "week" => 1,
      "theme" => "Awareness",
      "posts" => [
        {"type" => "Post", "day" => "Monday"},
        {"type" => "Reel", "day" => "Wednesday"}
      ]
    }
  ]
}
```

## 🔄 Próximos Pasos

1. **Agregar validaciones** para parámetros faltantes
2. **Mejorar error handling** en JavaScript
3. **Implementar loading states** durante generación
4. **Agregar persistencia** de planes en localStorage como respaldo
5. **Tests de integración** con Capybara para flujo completo

## 💡 Notas Importantes

- ✅ Usa POST-Redirect-GET pattern
- ✅ No usa modales ni formularios inline
- ✅ Maneja errores graciosamente
- ✅ Requiere marca persistida antes de generar
- ✅ Compatible con el sistema de design tokens existente