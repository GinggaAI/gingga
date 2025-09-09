#!/usr/bin/env ruby
# Script para ejecutar jobs pendientes manualmente
# Usage: bundle exec rails runner scripts/monitoring/execute_pending_jobs.rb

puts '=== EJECUTANDO JOBS PENDIENTES MANUALMENTE ==='

# Ver jobs pendientes antes de ejecutar
pending_jobs = SolidQueue::Job.where(finished_at: nil).limit(5)
puts "📋 Jobs pendientes encontrados: #{pending_jobs.count}"

if pending_jobs.empty?
  puts "✅ No hay jobs pendientes para ejecutar"
  exit
end

pending_jobs.each_with_index do |job, index|
  puts "\n#{index + 1}. Ejecutando: #{job.class_name}"
  puts "   Creado: #{job.created_at}"
  puts "   ID: #{job.id}"
  
  begin
    # Deserializar argumentos
    arguments = job.arguments || []
    
    puts "   ⏳ Procesando..."
    
    # Ejecutar el job usando perform_now
    job_class = job.class_name.constantize
    
    if arguments.any?
      job_class.perform_now(*arguments)
    else
      job_class.perform_now
    end
    
    # Marcar como completado
    job.update!(finished_at: Time.current)
    
    puts "   ✅ Completado exitosamente"
    
  rescue => e
    puts "   ❌ Error: #{e.message}"
    puts "   Stack trace: #{e.backtrace.first(3).join(', ')}"
    
    # Opcionalmente marcar como fallido
    # job.update!(finished_at: Time.current, failed: true)
  end
end

puts "\n=== EJECUCIÓN MANUAL COMPLETADA ==="

# Mostrar resumen final
remaining = SolidQueue::Job.where(finished_at: nil).count
puts "📊 Jobs pendientes restantes: #{remaining}"