#!/usr/bin/env ruby

puts "=== PRUEBA PASO A PASO: REFINE WITH VOXA ==="

# Obtener la estrategia actual
strategy = CreasStrategyPlan.find("cfddec59-8012-4f00-8d90-96cb90d9a9d5")
user = strategy.user

puts "\n📋 PASO 1: Verificar estrategia existente"
puts "   ✅ Estrategia ID: #{strategy.id}"
puts "   ✅ Estado: #{strategy.status}"
puts "   ✅ Mes: #{strategy.month}"
puts "   ✅ Usuario: #{user.email}"

puts "\n📋 PASO 2: Verificar que SolidQueue está funcionando"
active_workers = SolidQueue::Process.where("last_heartbeat_at > ?", 1.minute.ago).count
pending_jobs = SolidQueue::Job.where(finished_at: nil).count

puts "   Workers activos: #{active_workers}"
puts "   Jobs pendientes: #{pending_jobs}"

if active_workers == 0
  puts "   ❌ ERROR: No hay workers de SolidQueue activos"
  exit 1
end

puts "\n📋 PASO 3: Simular llamada al refinamiento (POST /planning/content_refinements)"
# Simular los parámetros que enviaría el formulario web

refinement_params = {
  strategy_plan_id: strategy.id,
  week_number: 2,  # Refinamos la semana 2
  additional_context: "Probar refinamiento automatizado con Voxa"
}

puts "   Parámetros de refinamiento:"
puts "   - strategy_plan_id: #{refinement_params[:strategy_plan_id]}"
puts "   - week_number: #{refinement_params[:week_number]}"
puts "   - additional_context: #{refinement_params[:additional_context]}"

puts "\n📋 PASO 4: Ejecutar el servicio de refinamiento"
begin
  # Usar el servicio directamente como lo haría el controlador
  service = Planning::ContentRefinementService.new(
    strategy: strategy,
    target_week: refinement_params[:week_number],
    user: user
  )

  result = service.call

  if result.success?
    puts "   ✅ Servicio ejecutado exitosamente"
    puts "   📄 Mensaje: #{result.success_message}"

    # Verificar que se creó el job
    puts "\n📋 PASO 5: Verificar job en cola"
    recent_jobs = SolidQueue::Job.where("created_at > ?", 30.seconds.ago).order(created_at: :desc)

    if recent_jobs.any?
      recent_jobs.each do |job|
        puts "   ✅ Job creado: #{job.class_name}"
        puts "   📅 Creado: #{job.created_at}"
        puts "   🎯 Estado: #{job.finished_at ? 'Completado' : 'Pendiente/Procesando'}"
      end
    else
      puts "   ⚠️  No se encontraron jobs recientes"
    end

  else
    puts "   ❌ ERROR en el servicio: #{result.error_message}"
    exit 1
  end

rescue => e
  puts "   ❌ EXCEPCIÓN: #{e.message}"
  puts "   Backtrace: #{e.backtrace[0..2].join("\n")}"
  exit 1
end

puts "\n📋 PASO 6: Monitorear progreso"
puts "   Para monitorear el progreso del job, usa:"
puts "   bundle exec rails runner scripts/monitoring/solidqueue_health.rb"

puts "\n✅ PRUEBA COMPLETADA EXITOSAMENTE"
puts "🎯 El refinamiento debería estar procesándose en segundo plano"
