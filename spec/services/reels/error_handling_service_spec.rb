require 'rails_helper'

RSpec.describe Reels::ErrorHandlingService do
  let(:controller) { double('Controller', current_user: user, reels_path: '/reels') }
  let(:user) { create(:user) }
  let(:reel) { create(:reel, user: user) }
  let(:reel_params) { { template: 'avatar_only' } }
  let(:service) { described_class.new(controller: controller) }

  describe '#handle_creation_error' do
    let(:creation_result) { { reel: reel } }

    context 'when presenter setup succeeds' do
      let(:presenter_result) do
        double('PresenterResult',
          success?: true,
          data: {
            presenter: double('Presenter'),
            view_template: 'reels/new'
          }
        )
      end

      before do
        allow_any_instance_of(Reels::PresenterService).to receive(:call).and_return(presenter_result)
      end

      it 'renders form with errors' do
        expect(controller).to receive(:instance_variable_set).with(:@reel, reel)
        expect(controller).to receive(:instance_variable_set).with(:@presenter, presenter_result.data[:presenter])
        expect(controller).to receive(:render).with('reels/new', status: :unprocessable_entity)

        service.handle_creation_error(creation_result, reel_params)
      end
    end

    context 'when presenter setup fails' do
      let(:presenter_result) do
        double('PresenterResult',
          success?: false,
          error: 'Presenter setup failed'
        )
      end

      before do
        allow_any_instance_of(Reels::PresenterService).to receive(:call).and_return(presenter_result)
      end

      it 'renders JSON error' do
        expect(controller).to receive(:render).with(
          json: { error: 'Presenter setup failed' },
          status: :unprocessable_entity
        )

        service.handle_creation_error(creation_result, reel_params)
      end
    end

    context 'when reel is nil but template is provided in params' do
      let(:creation_result) { { reel: nil } }

      before do
        presenter_result = double('PresenterResult', success?: true, data: { presenter: double, view_template: 'reels/new' })
        allow_any_instance_of(Reels::PresenterService).to receive(:call).and_return(presenter_result)
      end

      it 'uses template from params' do
        expect(Reels::PresenterService).to receive(:new).with(
          reel: nil,
          template: 'avatar_only',
          current_user: user
        ).and_call_original

        allow(controller).to receive(:instance_variable_set)
        allow(controller).to receive(:render)

        service.handle_creation_error(creation_result, reel_params)
      end
    end

    context 'when reel has template' do
      let(:reel_with_template) { create(:reel, user: user, template: 'avatar_and_video') }
      let(:creation_result) { { reel: reel_with_template } }

      before do
        presenter_result = double('PresenterResult', success?: true, data: { presenter: double, view_template: 'reels/new' })
        allow_any_instance_of(Reels::PresenterService).to receive(:call).and_return(presenter_result)
      end

      it 'uses template from reel' do
        expect(Reels::PresenterService).to receive(:new).with(
          reel: reel_with_template,
          template: 'avatar_and_video',
          current_user: user
        ).and_call_original

        allow(controller).to receive(:instance_variable_set)
        allow(controller).to receive(:render)

        service.handle_creation_error(creation_result, reel_params)
      end
    end
  end

  describe '#handle_form_setup_error' do
    it 'redirects with alert message' do
      error_message = 'Form setup failed'

      expect(controller).to receive(:redirect_to).with('/reels', alert: error_message)

      service.handle_form_setup_error(error_message)
    end
  end

  describe '#handle_edit_access_error' do
    it 'redirects with edit access error message' do
      expect(controller).to receive(:redirect_to).with(
        '/reels',
        alert: "Only draft reels can be edited"
      )

      service.handle_edit_access_error
    end
  end

  describe 'private methods' do
    describe '#setup_error_presenter' do
      let(:template) { 'avatar_only' }

      it 'calls PresenterService with correct parameters' do
        expect(Reels::PresenterService).to receive(:new).with(
          reel: reel,
          template: template,
          current_user: user
        ).and_call_original

        service.send(:setup_error_presenter, reel, template)
      end
    end

    describe '#render_form_with_errors' do
      let(:presenter) { double('Presenter') }
      let(:presenter_result) do
        double('PresenterResult', data: { presenter: presenter, view_template: 'reels/edit' })
      end

      it 'sets instance variables and renders template' do
        expect(controller).to receive(:instance_variable_set).with(:@reel, reel)
        expect(controller).to receive(:instance_variable_set).with(:@presenter, presenter)
        expect(controller).to receive(:render).with('reels/edit', status: :unprocessable_entity)

        service.send(:render_form_with_errors, reel, presenter_result)
      end
    end

    describe '#render_json_error' do
      it 'renders JSON error with unprocessable_entity status' do
        error_message = 'Something went wrong'

        expect(controller).to receive(:render).with(
          json: { error: error_message },
          status: :unprocessable_entity
        )

        service.send(:render_json_error, error_message)
      end
    end
  end
end
