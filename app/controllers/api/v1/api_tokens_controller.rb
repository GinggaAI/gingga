module Api
  module V1
    class ApiTokensController < ApplicationController
      before_action :authenticate_user!
      before_action :set_api_token, only: [ :show, :update, :destroy ]

      def index
        @api_tokens = current_user.api_tokens
        render json: @api_tokens.map { |token| ApiTokenSerializer.new(token).as_json }
      end

      def show
        render json: ApiTokenSerializer.new(@api_token).as_json
      end

      def create
        @api_token = current_user.api_tokens.build(api_token_params)

        if @api_token.save
          render json: ApiTokenSerializer.new(@api_token).as_json, status: :created
        else
          render json: { errors: @api_token.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @api_token.update(api_token_params)
          render json: ApiTokenSerializer.new(@api_token).as_json
        else
          render json: { errors: @api_token.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @api_token.destroy
        head :no_content
      end

      private

      def set_api_token
        @api_token = current_user.api_tokens.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Token not found" }, status: :not_found
      end

      def api_token_params
        params.require(:api_token).permit(:provider, :mode, :encrypted_token)
      end
    end
  end
end
