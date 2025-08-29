module Creas
  class VoxaContentService
    def initialize(strategy_plan:)
      @plan = strategy_plan
      @user = @plan.user
      @brand = @plan.brand
    end

    def call
      # Ensure we have fresh ActiveRecord instances to avoid class reloading issues
      fresh_plan = @plan.is_a?(CreasStrategyPlan) ? CreasStrategyPlan.find(@plan.id) : @plan
      @plan = fresh_plan  # Update instance variable with fresh plan
      @user = @plan.user   # Update user reference from fresh plan
      @brand = @plan.brand # Update brand reference from fresh plan

      Rails.logger.info "VoxaContentService: Starting content refinement for strategy plan #{@plan.id} (user: #{@user.id}, brand: #{@brand&.id})"

      # Check if strategy is already being processed
      if @plan.status == "processing"
        Rails.logger.warn "VoxaContentService: Strategy plan #{@plan.id} is already in processing status"
        raise StandardError, "Content refinement is already in progress. Please wait a few minutes and refresh the page."
      end

      # Log current content state
      current_content_count = @plan.creas_content_items.count
      Rails.logger.info "VoxaContentService: Current content items count: #{current_content_count}"

      # Calculate number of batches needed (max 7 items per batch)
      total_batches = calculate_batches_needed(current_content_count)
      batch_id = SecureRandom.uuid

      Rails.logger.info "VoxaContentService: Starting batch processing for strategy plan #{@plan.id} with #{total_batches} batches (batch_id: #{batch_id})"

      # Update strategy plan status to pending (will be updated to processing by first batch job)
      @plan.update!(status: :pending)
      Rails.logger.info "VoxaContentService: Strategy plan #{@plan.id} status updated to pending"

      # Queue first batch job for Voxa processing
      ::GenerateVoxaContentBatchJob.perform_later(@plan.id, 1, total_batches, batch_id)
      Rails.logger.info "VoxaContentService: GenerateVoxaContentBatchJob batch 1/#{total_batches} queued for strategy plan #{@plan.id}"

      # Return the plan immediately (status: pending)
      @plan
    rescue StandardError => e
      Rails.logger.error "VoxaContentService: Failed to start content refinement for strategy plan #{@plan.id}: #{e.message}"
      Rails.logger.error "VoxaContentService: Error backtrace: #{e.backtrace.join("\n")}" if e.backtrace
      raise
    end

    private

    def calculate_batches_needed(content_count)
      return 1 if content_count == 0 # Will be created by ContentItemInitializerService

      # Calculate batches with max 7 items per batch
      batch_size = 7
      (content_count.to_f / batch_size).ceil
    end
  end
end
