# Voxa Content Refinement - Guía de Pruebas (Rails Console)

**Fecha:** 19 de Agosto, 2025  
**Autor:** Claude Code AI  
**Propósito:** Guía paso a paso para probar la implementación de Voxa usando Rails Console

---

Esta guía te permitirá probar manualmente cada componente de la integración de Voxa, desde la preparación de datos hasta la generación de contenido refinado. Sigue los pasos en orden para entender el flujo completo y verificar que todo funcione correctamente.

---

## 🔐 0. Setup Inicial: Preparar Usuario y Marca

Primero necesitas un usuario con una marca y un plan de estrategia generado por Noctua:

```ruby
# Encontrar o crear usuario
user = User.find_by(email: "tu_email@example.com")

# Si no existe, crear uno de prueba
unless user
  user = User.create!(
    email: "test@example.com",
    password: "password123",
    first_name: "Test",
    last_name: "User"
  )
end

# Verificar que el usuario exista
puts "👤 Usuario: #{user.email} (ID: #{user.id})"
```

```ruby
# Crear una marca completa para el usuario
brand = Brand.create!(
  user: user,
  name: "TestBrand Co",
  slug: "testbrand-co",
  industry: "Technology",
  value_proposition: "Innovación tecnológica accesible",
  mission: "Democratizar la tecnología para todos",
  voice: "friendly",
  content_language: "es-ES",
  banned_words_list: "",
  guardrails: {
    "banned_words" => [],
    "tone_no_go" => ["aggressive", "promotional"],
    "claims_rules" => "No hacer afirmaciones médicas"
  }
)

puts "🏢 Marca creada: #{brand.name} (ID: #{brand.id})"
```

```ruby
# Crear canales de marca (necesarios para extraer priority_platforms)
instagram_channel = BrandChannel.create!(
  brand: brand,
  platform: :instagram,
  handle: "@testbrand",
  is_active: true
)

tiktok_channel = BrandChannel.create!(
  brand: brand,
  platform: :tiktok, 
  handle: "@testbrand_tiktok",
  is_active: true
)

puts "📱 Canales creados: Instagram, TikTok"
```

---

## 📋 1. Crear Plan de Estrategia con Datos de Noctua

Necesitas un `CreasStrategyPlan` con datos realistas de Noctua en el campo `raw_payload`:

```ruby
# Payload de ejemplo que simula datos generados por Noctua
noctua_payload = {
  "brand_name" => "TestBrand Co",
  "brand_slug" => "testbrand-co",
  "strategy_name" => "Estrategia Agosto 2025",
  "month" => "2025-08",
  "general_theme" => "Innovación Tecnológica",
  "objective_of_the_month" => "awareness",
  "frequency_per_week" => 3,
  "platforms" => ["Instagram", "TikTok"],
  "tone_style" => "Amigable pero profesional",
  "content_language" => "es-ES",
  "account_language" => "es-ES",
  "target_region" => "España",
  "timezone" => "Europe/Madrid",
  "post_types" => ["Video", "Image", "Carousel"],
  "weekly_plan" => [
    {
      "week" => 1,
      "publish_cadence" => 3,
      "ideas" => [
        {
          "id" => "202508-testbrand-co-w1-i1-C",
          "status" => "draft",
          "title" => "Innovación Tech para Todos",
          "hook" => "¿Sabías que la tecnología puede ser más accesible?",
          "description" => "Explicamos cómo las nuevas tecnologías se están volviendo más accesibles para el usuario común, rompiendo barreras tradicionales.",
          "platform" => "Instagram Reels", 
          "pilar" => "C",
          "recommended_template" => "only_avatars",
          "video_source" => "none",
          "visual_notes" => "Avatar hablando directamente a cámara",
          "kpi_focus" => "reach",
          "success_criteria" => "≥10K views",
          "beats_outline" => ["Hook: Pregunta provocativa", "Valor: 3 ejemplos concretos", "CTA: Comenta tu experiencia"],
          "cta" => "¿Cuál es tu tecnología favorita? Coméntanos 👇"
        },
        {
          "id" => "202508-testbrand-co-w1-i2-R",
          "status" => "draft", 
          "title" => "Casos de Éxito Reales",
          "hook" => "Esto es lo que pasó cuando María probó nuestra solución...",
          "description" => "Historia de éxito de una usuaria real que transformó su flujo de trabajo usando nuestras herramientas tecnológicas.",
          "platform" => "Instagram Reels",
          "pilar" => "R", 
          "recommended_template" => "narration_over_7_images",
          "video_source" => "none",
          "visual_notes" => "Imágenes del antes/después del proceso",
          "kpi_focus" => "saves",
          "success_criteria" => "≥8% saves",
          "beats_outline" => ["Hook: Historia personal", "Problema: Situación inicial", "Solución: Proceso paso a paso", "Resultado: Transformación", "Prueba social: Testimonios", "Beneficio: Valor obtenido", "CTA: Pruébalo tú"],
          "cta" => "Guarda este post y cuéntanos tu historia 💾"
        },
        {
          "id" => "202508-testbrand-co-w1-i3-E",
          "status" => "draft",
          "title" => "Tutorial Escalabilidad",
          "hook" => "3 pasos para escalar tu proyecto tech sin quebrar el presupuesto",
          "description" => "Tutorial práctico sobre cómo hacer crecer un proyecto tecnológico de manera sostenible y económica.",
          "platform" => "Instagram Reels",
          "pilar" => "E",
          "recommended_template" => "avatar_and_video", 
          "video_source" => "external",
          "visual_notes" => "Avatar + clips de herramientas",
          "kpi_focus" => "saves",
          "success_criteria" => "≥12% saves",
          "beats_outline" => ["Hook: Promesa específica", "Paso 1: Planificación", "Paso 2: Automatización", "Paso 3: Optimización", "CTA: Implementa hoy"],
          "cta" => "¿Cuál vas a implementar primero? 🚀"
        }
      ]
    }
  ]
}

puts "📊 Payload de Noctua preparado con #{noctua_payload['weekly_plan'][0]['ideas'].length} ideas"
```

```ruby
# Crear el plan de estrategia
strategy_plan = CreasStrategyPlan.create!(
  user: user,
  brand: brand,
  month: "2025-08",
  objective_of_the_month: "awareness",
  frequency_per_week: 3,
  raw_payload: noctua_payload,
  monthly_themes: ["Innovación", "Accesibilidad", "Democratización"],
  brand_snapshot: {
    "name" => brand.name,
    "industry" => brand.industry,
    "voice" => brand.voice
  }
)

puts "📈 Plan de estrategia creado: #{strategy_plan.id}"
puts "   Mes: #{strategy_plan.month}"
puts "   Objetivo: #{strategy_plan.objective_of_the_month}"
puts "   Frecuencia: #{strategy_plan.frequency_per_week} posts/semana"
```

---

## 🔍 2. Verificar StrategyPlanFormatter

Antes de llamar a Voxa, verifica que el formateador funcione correctamente:

```ruby
# Crear formateador y probar el método for_voxa
formatter = Creas::StrategyPlanFormatter.new(strategy_plan)
formatted_data = formatter.for_voxa

puts "📋 Datos formateados para Voxa:"
puts "   Marca: #{formatted_data.dig("strategy", "brand_name")}"
puts "   Mes: #{formatted_data.dig("strategy", "month")}"
puts "   Ideas: #{formatted_data.dig("strategy", "weekly_plan", 0, "ideas")&.length || 0}"

# Mostrar primera idea como ejemplo
first_idea = formatted_data.dig("strategy", "weekly_plan", 0, "ideas", 0)
if first_idea
  puts "\n📝 Primera idea:"
  puts "   ID: #{first_idea["id"]}"
  puts "   Título: #{first_idea["title"]}"
  puts "   Template: #{first_idea["recommended_template"]}"
  puts "   Pilar: #{first_idea["pilar"]}"
end
```

---

## 🤖 3. Probar la Construcción del Contexto de Marca

El servicio necesita construir un contexto de marca que se envía junto con los datos de estrategia:

```ruby
# Inicializar el servicio Voxa
service = Creas::VoxaContentService.new(strategy_plan: strategy_plan)

# Probar la construcción del contexto de marca (método privado)
brand_context = service.send(:build_brand_context, brand)

puts "🏢 Contexto de marca construido:"
puts "   Industria: #{brand_context.dig("brand", "industry")}"
puts "   Propuesta de valor: #{brand_context.dig("brand", "value_proposition")}"
puts "   Plataformas: #{brand_context.dig("brand", "priority_platforms")&.join(", ")}"
puts "   Idioma: #{brand_context.dig("brand", "languages", "content_language")}"

# Verificar guardrails
guardrails = brand_context.dig("brand", "guardrails")
puts "   Guardrails configurados: #{guardrails&.keys&.join(", ") || "ninguno"}"
```

---

## ⚙️ 4. Verificar Prompts de Voxa

Antes de llamar a la API, verifica que los prompts se generen correctamente:

```ruby
# Obtener los datos necesarios
strategy_plan_data = formatter.for_voxa
brand_context = service.send(:build_brand_context, brand)

# Generar prompt del sistema
system_prompt = Creas::Prompts.voxa_system(strategy_plan_data: strategy_plan_data)

puts "🔧 Prompt del sistema generado:"
puts "   Longitud: #{system_prompt.length} caracteres"
puts "   Contiene versión: #{system_prompt.include?(Creas::Prompts::VOXA_VERSION)}"
puts "   Contiene contract: #{system_prompt.include?("ITEM_OBJ")}"

# Generar prompt del usuario
user_prompt = Creas::Prompts.voxa_user(strategy_plan_data: strategy_plan_data, brand_context: brand_context)

puts "\n👤 Prompt del usuario generado:"
puts "   Longitud: #{user_prompt.length} caracteres"
puts "   Contiene datos de estrategia: #{user_prompt.include?("Strategy Plan Data")}"
puts "   Contiene contexto de marca: #{user_prompt.include?("Brand Context")}"

# Mostrar primeras líneas para verificar formato
puts "\n📄 Primeras líneas del prompt de usuario:"
puts user_prompt.lines[0..5].map(&:strip).join("\n")
```

---

## 🚀 5. Ejecutar el Servicio Voxa (Simulado)

Para probar sin consumir API real, podemos simular la respuesta de OpenAI:

```ruby
# Respuesta simulada que Voxa debería generar
mock_voxa_response = {
  "items" => [
    {
      "id" => "20250819-w1-i1",
      "origin_id" => "202508-testbrand-co-w1-i1-C",
      "origin_source" => "weekly_plan",
      "week" => 1,
      "week_index" => 1,
      "content_name" => "Innovación Tech Accesible",
      "status" => "in_production",
      "creation_date" => Date.current.iso8601,
      "publish_date" => (Date.current + 4.days).iso8601,
      "publish_datetime_local" => (Date.current + 4.days).strftime("%Y-%m-%dT18:00:00"),
      "timezone" => "Europe/Madrid",
      "content_type" => "Video",
      "platform" => "Instagram Reels",
      "aspect_ratio" => "9:16",
      "language" => "es-ES",
      "pilar" => "C",
      "template" => "only_avatars",
      "video_source" => "none",
      "post_description" => "Contenido educativo sobre accesibilidad tecnológica para audiencias generales",
      "text_base" => "¿Sabías que la tecnología puede ser más accesible? Aquí te explico 3 formas de democratizar el acceso a herramientas digitales. ¿Cuál es tu favorita? 👇",
      "hashtags" => "#tecnología #innovación #accesibilidad #digital",
      "subtitles" => { "mode" => "platform_auto", "languages" => ["es-ES"] },
      "dubbing" => { "enabled" => false, "languages" => [] },
      "shotplan" => {
        "scenes" => [
          {
            "id" => 1,
            "role" => "Hook",
            "type" => "avatar",
            "visual" => "Avatar en primer plano, fondo tecnológico suave",
            "on_screen_text" => "¿TECNOLOGÍA ACCESIBLE?",
            "voiceover" => "¿Sabías que la tecnología puede ser más accesible de lo que piensas?",
            "avatar_id" => "avatar_sarah",
            "voice_id" => "voice_es_female_1"
          },
          {
            "id" => 2,
            "role" => "Development", 
            "type" => "avatar",
            "visual" => "Avatar explicativo con gestos naturales",
            "on_screen_text" => "3 FORMAS DE DEMOCRATIZAR",
            "voiceover" => "Te voy a explicar tres formas concretas de democratizar el acceso a herramientas digitales",
            "avatar_id" => "avatar_sarah",
            "voice_id" => "voice_es_female_1"
          },
          {
            "id" => 3,
            "role" => "Close",
            "type" => "avatar",
            "visual" => "Avatar sonriente, llamada a la acción",
            "on_screen_text" => "¿CUÁL PREFIERES?",
            "voiceover" => "¿Cuál de estas opciones te parece más interesante? Cuéntanos en los comentarios",
            "avatar_id" => "avatar_sarah",
            "voice_id" => "voice_es_female_1"
          }
        ],
        "beats" => []
      },
      "assets" => {
        "external_video_url" => "",
        "video_urls" => [],
        "video_prompts" => [],
        "broll_suggestions" => ["Personas usando tecnología", "Interfaces amigables", "Diversidad digital"]
      },
      "accessibility" => { "captions" => true, "srt_export" => true },
      "kpi_focus" => "reach",
      "success_criteria" => "≥10K views",
      "compliance_check" => "ok"
    }
  ]
}

puts "🎭 Respuesta simulada de Voxa preparada"
puts "   Elementos: #{mock_voxa_response["items"].length}"
puts "   Primer elemento ID: #{mock_voxa_response["items"][0]["id"]}"
```

```ruby
# Simular llamada al servicio con respuesta mock
begin
  # Mockear la respuesta de OpenAI temporalmente
  original_method = service.method(:openai_chat!)
  
  def service.openai_chat!(system_msg:, user_msg:)
    # Simular la respuesta JSON de OpenAI
    mock_response = {
      "items" => [
        {
          "id" => "20250819-w1-i1",
          "origin_id" => "202508-testbrand-co-w1-i1-C",
          "origin_source" => "weekly_plan",
          "week" => 1,
          "week_index" => 1,
          "content_name" => "Innovación Tech Accesible",
          "status" => "in_production",
          "creation_date" => Date.current.iso8601,
          "publish_date" => (Date.current + 4.days).iso8601,
          "publish_datetime_local" => (Date.current + 4.days).strftime("%Y-%m-%dT18:00:00"),
          "timezone" => "Europe/Madrid",
          "content_type" => "Video",
          "platform" => "Instagram Reels",
          "aspect_ratio" => "9:16",
          "language" => "es-ES",
          "pilar" => "C",
          "template" => "only_avatars",
          "video_source" => "none",
          "post_description" => "Contenido educativo sobre accesibilidad tecnológica",
          "text_base" => "¿Sabías que la tecnología puede ser más accesible? Aquí 3 formas de democratizar el acceso. ¿Cuál prefieres? 👇",
          "hashtags" => "#tecnología #innovación #accesibilidad #digital",
          "subtitles" => { "mode" => "platform_auto", "languages" => ["es-ES"] },
          "dubbing" => { "enabled" => false, "languages" => [] },
          "shotplan" => {
            "scenes" => [
              {
                "id" => 1,
                "role" => "Hook",
                "type" => "avatar",
                "visual" => "Avatar primer plano",
                "on_screen_text" => "¿TECNOLOGÍA ACCESIBLE?",
                "voiceover" => "¿Sabías que la tecnología puede ser más accesible?",
                "avatar_id" => "avatar_sarah",
                "voice_id" => "voice_es_female_1"
              }
            ],
            "beats" => []
          },
          "assets" => {
            "external_video_url" => "",
            "video_urls" => [],
            "video_prompts" => [],
            "broll_suggestions" => ["Tecnología accesible"]
          },
          "accessibility" => { "captions" => true, "srt_export" => true },
          "kpi_focus" => "reach",
          "success_criteria" => "≥10K views",
          "compliance_check" => "ok"
        }
      ]
    }
    
    puts "🔄 Simulando respuesta de OpenAI..."
    return mock_response
  end
  
  # Ejecutar el servicio
  result = service.call
  puts "✅ Servicio ejecutado exitosamente"
  
rescue => e
  puts "❌ Error en el servicio: #{e.message}"
  puts e.backtrace[0..3]
end
```

---

## 📊 6. Verificar Creación de Content Items

Después de ejecutar el servicio, verifica que los registros se hayan creado correctamente:

```ruby
# Verificar que se crearon los content items
content_items = strategy_plan.creas_content_items.reload

puts "📈 Resultado de la refinación:"
puts "   Content items creados: #{content_items.count}"

if content_items.any?
  first_item = content_items.first
  puts "\n📝 Primer content item:"
  puts "   ID: #{first_item.content_id}"
  puts "   Origen: #{first_item.origin_id}"
  puts "   Nombre: #{first_item.content_name}"
  puts "   Estado: #{first_item.status}"
  puts "   Template: #{first_item.template}"
  puts "   Pilar: #{first_item.pilar}"
  puts "   Semana: #{first_item.week}"
  
  # Verificar fechas
  puts "\n📅 Fechas:"
  puts "   Creación: #{first_item.creation_date}"
  puts "   Publicación: #{first_item.publish_date}"
  puts "   Publicación local: #{first_item.publish_datetime_local}"
  
  # Verificar contenido
  puts "\n📄 Contenido:"
  puts "   Descripción: #{first_item.post_description[0..100]}..."
  puts "   Texto base: #{first_item.text_base[0..100]}..."
  puts "   Hashtags: #{first_item.hashtags}"
  
  # Verificar JSONB
  puts "\n🎬 Shotplan:"
  puts "   Escenas: #{first_item.scenes.length}"
  puts "   Beats: #{first_item.beats.length}"
  puts "   Primera escena: #{first_item.scenes.first&.dig("role")}"
  
  puts "\n📁 Assets:"
  puts "   Videos externos: #{first_item.external_videos.length}"
  puts "   Sugerencias B-roll: #{first_item.assets.dig("broll_suggestions")&.length || 0}"
end
```

---

## 🔄 7. Probar Idempotencia

Una característica importante es que ejecutar Voxa múltiples veces no debe crear duplicados:

```ruby
# Contar items antes de la segunda ejecución
initial_count = strategy_plan.creas_content_items.count
puts "📊 Items antes de segunda ejecución: #{initial_count}"

# Ejecutar el servicio por segunda vez
begin
  service = Creas::VoxaContentService.new(strategy_plan: strategy_plan)
  
  # Aplicar el mismo mock que antes
  def service.openai_chat!(system_msg:, user_msg:)
    mock_response = {
      "items" => [
        {
          "id" => "20250819-w1-i1",
          "origin_id" => "202508-testbrand-co-w1-i1-C",
          "content_name" => "Innovación Tech Accesible ACTUALIZADO",  # Cambio para probar actualización
          "status" => "in_production",
          "creation_date" => Date.current.iso8601,
          "publish_date" => (Date.current + 4.days).iso8601,
          "publish_datetime_local" => (Date.current + 4.days).strftime("%Y-%m-%dT18:00:00"),
          "timezone" => "Europe/Madrid",
          "content_type" => "Video",
          "platform" => "Instagram Reels",
          "aspect_ratio" => "9:16",
          "language" => "es-ES",
          "pilar" => "C",
          "template" => "only_avatars",
          "video_source" => "none",
          "post_description" => "Descripción actualizada",
          "text_base" => "Texto base actualizado",
          "hashtags" => "#tecnología #actualizado",
          "shotplan" => { "scenes" => [], "beats" => [] },
          "assets" => { "broll_suggestions" => [] },
          "subtitles" => { "mode" => "platform_auto", "languages" => ["es-ES"] },
          "dubbing" => { "enabled" => false, "languages" => [] },
          "accessibility" => { "captions" => true },
          "kpi_focus" => "reach",
          "success_criteria" => "≥10K views",
          "compliance_check" => "ok",
          "origin_source" => "weekly_plan",
          "week" => 1,
          "week_index" => 1
        }
      ]
    }
    return mock_response
  end
  
  result = service.call
  puts "✅ Segunda ejecución completada"
  
rescue => e
  puts "❌ Error en segunda ejecución: #{e.message}"
end

# Verificar idempotencia
final_count = strategy_plan.creas_content_items.reload.count
puts "📊 Items después de segunda ejecución: #{final_count}"

if final_count == initial_count
  puts "✅ Idempotencia confirmada - no se crearon duplicados"
  
  # Verificar si se actualizó el contenido
  updated_item = strategy_plan.creas_content_items.find_by(content_id: "20250819-w1-i1")
  if updated_item&.content_name&.include?("ACTUALIZADO")
    puts "✅ Actualización confirmada - el contenido se modificó"
  else
    puts "ℹ️ No se detectaron cambios en el contenido"
  end
else
  puts "⚠️ Se crearon #{final_count - initial_count} items adicionales - verificar lógica de idempotencia"
end
```

---

## 🎨 8. Probar ContentItemFormatter

El formatter convierte los content items en formato amigable para el frontend:

```ruby
# Tomar el primer content item
content_item = strategy_plan.creas_content_items.first

if content_item
  # Usar el formatter de clase
  formatted_hash = Creas::ContentItemFormatter.call(content_item)
  
  puts "🎨 Contenido formateado para frontend:"
  puts "   ID: #{formatted_hash[:id]}"
  puts "   Origen: #{formatted_hash[:origin_id]}"
  puts "   Nombre: #{formatted_hash[:content_name]}"
  puts "   Estado: #{formatted_hash[:status]}"
  
  # Verificar formateo de fechas
  puts "\n📅 Fechas formateadas:"
  puts "   Creación: #{formatted_hash[:creation_date]}"
  puts "   Publicación: #{formatted_hash[:publish_date]}"
  
  # Verificar formateo de hashtags
  puts "\n🏷️ Hashtags formateados:"
  puts "   Array: #{formatted_hash[:hashtags].inspect}"
  puts "   Tipo: #{formatted_hash[:hashtags].class}"
  
  # Verificar campos derivados del meta
  puts "\n📊 Metadatos:"
  puts "   KPI Focus: #{formatted_hash[:kpi_focus]}"
  puts "   Criterio de éxito: #{formatted_hash[:success_criteria]}"
  puts "   Compliance: #{formatted_hash[:compliance_check]}"
  
  # Verificar estructura de escenas/beats según template
  if content_item.template == "only_avatars"
    puts "\n🎭 Escenas (only_avatars):"
    puts "   Cantidad: #{formatted_hash[:scenes].length}"
    puts "   Primera escena: #{formatted_hash[:scenes].first&.dig(:role)}"
  elsif content_item.template == "narration_over_7_images"
    puts "\n🖼️ Beats (narration_over_7_images):"
    puts "   Cantidad: #{formatted_hash[:beats].length}"
  end
  
else
  puts "❌ No hay content items para formatear"
end
```

---

## 🧹 9. Estadísticas y Limpieza

Generar estadísticas finales y preparar para limpieza:

```ruby
# Estadísticas del plan de estrategia
stats = strategy_plan.content_stats
puts "📊 Estadísticas de contenido:"
stats.each do |(status, template, video_source), count|
  puts "   #{status} | #{template} | #{video_source}: #{count} items"
end

# Items de la semana actual (si estamos en agosto 2025)
current_week_items = strategy_plan.current_week_items
puts "\n📅 Items de la semana actual: #{current_week_items.count}"

# Resumen por pilar
pillar_counts = strategy_plan.creas_content_items.group(:pilar).count
puts "\n🏛️ Distribución por pilar CREAS:"
%w[C R E A S].each do |pilar|
  count = pillar_counts[pilar] || 0
  puts "   #{pilar}: #{count} items"
end

# Resumen por template
template_counts = strategy_plan.creas_content_items.group(:template).count
puts "\n🎬 Distribución por template:"
template_counts.each do |template, count|
  puts "   #{template}: #{count} items"
end
```

```ruby
# Mostrar todos los content_ids creados
content_ids = strategy_plan.creas_content_items.pluck(:content_id)
puts "\n🆔 Content IDs creados:"
content_ids.each { |id| puts "   - #{id}" }

puts "\n✅ Prueba completa de Voxa finalizada"
puts "   Total de items creados: #{strategy_plan.creas_content_items.count}"
puts "   Plan de estrategia: #{strategy_plan.id}"
puts "   Usuario: #{user.email}"
puts "   Marca: #{brand.name}"
```

## 🗑️ Limpieza (Opcional)

Para limpiar los datos de prueba después de terminar:

```ruby
# ⚠️ CUIDADO: Esto eliminará todos los datos de prueba
puts "🗑️ Para limpiar datos de prueba, ejecuta:"
puts ""
puts "# Eliminar content items"
puts "strategy_plan.creas_content_items.destroy_all"
puts ""
puts "# Eliminar plan de estrategia"
puts "strategy_plan.destroy"
puts ""
puts "# Eliminar marca y canales"
puts "brand.brand_channels.destroy_all"
puts "brand.destroy"
puts ""
puts "# Eliminar usuario (si es de prueba)"
puts "user.destroy if user.email == 'test@example.com'"

# Descomenta las siguientes líneas para ejecutar la limpieza:
# strategy_plan.creas_content_items.destroy_all
# strategy_plan.destroy
# brand.brand_channels.destroy_all  
# brand.destroy
# user.destroy if user.email == 'test@example.com'
# puts "✅ Datos de prueba eliminados"
```

---

## 🎯 Criterios de Éxito

Si todos los pasos anteriores funcionaron correctamente, deberías ver:

- ✅ **Usuario y marca creados** con datos completos
- ✅ **Plan de estrategia** con payload de Noctua realista  
- ✅ **StrategyPlanFormatter** generando estructura correcta para Voxa
- ✅ **Contexto de marca** construido con plataformas y guardrails
- ✅ **Prompts de Voxa** generados con la estructura esperada
- ✅ **CreasContentItems** creados en base de datos
- ✅ **Idempotencia** confirmada (sin duplicados en segunda ejecución)
- ✅ **ContentItemFormatter** transformando datos para frontend
- ✅ **Estadísticas** mostrando distribución correcta por pilar y template

## ⚠️ Problemas Comunes y Soluciones

### "NoMethodError: undefined method for_voxa"
- **Causa:** StrategyPlanFormatter no tiene el método `for_voxa`  
- **Solución:** Verifica que el método esté implementado en el formatter

### "ActiveRecord::RecordInvalid: Validation failed"
- **Causa:** Datos del mock no cumplen validaciones del modelo
- **Solución:** Revisa las validaciones en `CreasContentItem` y ajusta el mock

### "KeyError: key not found: items"
- **Causa:** Respuesta de OpenAI no tiene la estructura esperada
- **Solución:** Verifica el formato del mock response y los prompts

### "Associación not found" 
- **Causa:** Referencias entre modelos no están correctas
- **Solución:** Verifica que user, brand, y strategy_plan estén relacionados correctamente

---

**¡Listo!** Con esta guía puedes probar paso a paso toda la implementación de Voxa y entender cómo funciona cada componente del sistema.