#!/usr/bin/env ruby
# SolidQueue Health Check Script
# Usage: bundle exec rails runner scripts/monitoring/solidqueue_health.rb

class SolidQueueHealthCheck
  def self.run
    puts "=== SOLID QUEUE HEALTH CHECK ==="
    puts "Timestamp: #{Time.current}"

    # Métricas básicas
    total_jobs = SolidQueue::Job.count
    pending_jobs = SolidQueue::Job.where(finished_at: nil).count
    completed_jobs = SolidQueue::Job.where.not(finished_at: nil).count

    puts "📊 MÉTRICAS GENERALES:"
    puts "  Total jobs: #{total_jobs}"
    puts "  Pendientes: #{pending_jobs}"
    puts "  Completados: #{completed_jobs}"

    # Alertas
    old_pending = SolidQueue::Job.where(finished_at: nil)
                                 .where('created_at < ?', 1.hour.ago).count

    if old_pending > 0
      puts "⚠️  ALERTA: #{old_pending} jobs pendientes de más de 1 hora"
    end

    # Jobs por tipo
    puts "\n📋 JOBS POR TIPO:"
    SolidQueue::Job.group(:class_name).count.each do |job_class, count|
      pending_count = SolidQueue::Job.where(class_name: job_class, finished_at: nil).count
      puts "  #{job_class}: #{count} total (#{pending_count} pendientes)"
    end

    # Jobs específicos importantes
    puts "\n🎯 JOBS CRÍTICOS:"

    # CheckVideoStatusJob
    video_jobs_pending = SolidQueue::Job.where(class_name: 'CheckVideoStatusJob', finished_at: nil).count
    puts "  🎥 CheckVideoStatusJob pendientes: #{video_jobs_pending}"

    # Content generation jobs
    noctua_pending = SolidQueue::Job.where(class_name: 'GenerateNoctuaStrategyBatchJob', finished_at: nil).count
    puts "  🧠 Noctua Strategy Jobs pendientes: #{noctua_pending}"

    voxa_pending = SolidQueue::Job.where(class_name: 'GenerateVoxaContentBatchJob', finished_at: nil).count
    puts "  📝 Voxa Content Jobs pendientes: #{voxa_pending}"

    # Jobs programados para el futuro
    future_jobs = SolidQueue::Job.where('scheduled_at > ?', Time.current).count
    if future_jobs > 0
      puts "\n⏰ Jobs programados para el futuro: #{future_jobs}"
    end

    # Recomendaciones
    puts "\n💡 RECOMENDACIONES:"

    if pending_jobs > 10
      puts "  - Considerar iniciar workers de SolidQueue: bundle exec solid_queue"
    end

    if old_pending > 5
      puts "  - Investigar jobs pendientes antiguos (>1 hora): #{old_pending} encontrados"
    end

    completed_old = SolidQueue::Job.where.not(finished_at: nil)
                                   .where('finished_at < ?', 7.days.ago).count
    if completed_old > 100
      puts "  - Limpiar jobs completados antiguos: #{completed_old} jobs de >7 días"
    end

    if pending_jobs == 0 && old_pending == 0
      puts "  ✅ Todo en orden - sistema funcionando correctamente"
    end

    puts "\n✅ Health check completado"
  end
end

# Ejecutar el health check si este archivo es ejecutado directamente
if __FILE__ == $0 || (defined?(Rails) && Rails.env)
  SolidQueueHealthCheck.run
end
