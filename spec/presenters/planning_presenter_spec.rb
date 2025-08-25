require 'rails_helper'

RSpec.describe PlanningPresenter do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { create(:user) }
  let(:brand) { create(:brand, user: user) }
  let(:presenter) { described_class.new(params, brand: brand) }

  describe '#display_month' do
    context 'with valid month parameter' do
      let(:params) { { month: '2025-08' } }

      it 'formats month correctly' do
        expect(presenter.display_month).to eq('August 2025')
      end
    end

    context 'with single digit month' do
      let(:params) { { month: '2025-8' } }

      it 'formats month correctly' do
        expect(presenter.display_month).to eq('August 2025')
      end
    end

    context 'with missing month parameter' do
      let(:params) { {} }

      it 'returns current month' do
        travel_to Date.new(2025, 8, 15) do
          expect(presenter.display_month).to eq('August 2025')
        end
      end
    end

    context 'with malformed month parameter' do
      let(:params) { { month: '<script>alert("xss")</script>' } }

      it 'returns safe fallback' do
        expect(presenter.display_month).to eq('Invalid Month')
      end
    end

    context 'with invalid date format' do
      let(:params) { { month: '2025-13' } }

      it 'returns safe fallback' do
        expect(presenter.display_month).to eq('Invalid Month')
      end
    end

    context 'when an exception occurs' do
      let(:params) { { month: '2025-08' } }

      before do
        allow(presenter).to receive(:safe_month_param).and_raise(StandardError)
      end

      it 'returns safe fallback on exception' do
        expect(presenter.display_month).to eq('Invalid Month')
      end
    end

    context 'with nil month string' do
      let(:params) { {} }

      before do
        allow(presenter).to receive(:current_month).and_return(nil)
      end

      it 'handles nil month gracefully' do
        expect(presenter.display_month).to eq('Invalid Month')
      end
    end

    context 'with invalid year/month combination' do
      let(:params) { { month: '2025-0' } }

      it 'returns safe fallback' do
        expect(presenter.display_month).to eq('Invalid Month')
      end
    end
  end

  describe '#safe_month_for_js' do
    context 'with valid month parameter' do
      let(:params) { { month: '2025-08' } }

      it 'returns sanitized month string' do
        expect(presenter.safe_month_for_js).to eq('2025-08')
      end
    end

    context 'with malicious input' do
      let(:params) { { month: "2025-08'; alert('xss'); //" } }

      it 'returns sanitized safe value' do
        expect(presenter.safe_month_for_js).to eq('2025-8') # current fallback
      end
    end

    context 'with missing month' do
      let(:params) { {} }

      it 'returns current month in safe format' do
        travel_to Date.new(2025, 8, 15) do
          expect(presenter.safe_month_for_js).to eq('2025-8')
        end
      end
    end

    context 'when an exception occurs' do
      let(:params) { { month: '2025-08' } }

      before do
        allow(presenter).to receive(:safe_month_param).and_raise(StandardError)
      end

      it 'returns current month on exception' do
        travel_to Date.new(2025, 8, 15) do
          expect(presenter.safe_month_for_js).to eq('2025-8')
        end
      end
    end

    context 'with non-string month parameter' do
      let(:params) { { month: 123 } }

      it 'returns current month for non-string input' do
        travel_to Date.new(2025, 8, 15) do
          expect(presenter.safe_month_for_js).to eq('2025-8')
        end
      end
    end
  end

  describe '#current_plan_json' do
    context 'with existing plan' do
      let!(:plan) { create(:creas_strategy_plan, brand: brand, month: '2025-08') }
      let(:params) { { month: '2025-08' } }

      it 'returns plan as JSON' do
        expect(presenter.current_plan_json).to include(plan.strategy_name)
      end
    end

    context 'without existing plan' do
      let(:params) { { month: '2025-08' } }

      it 'returns null' do
        expect(presenter.current_plan_json).to eq('null')
      end
    end

    context 'with plan_id parameter' do
      let!(:plan) { create(:creas_strategy_plan, brand: brand, month: '2024-12') }
      let(:params) { { plan_id: plan.id } }

      it 'returns specific plan by ID' do
        expect(presenter.current_plan_json).to include(plan.strategy_name)
      end
    end

    context 'with missing month parameter (should use current month)' do
      let(:params) { {} }

      it 'searches for current month plan' do
        travel_to Date.new(2025, 8, 15) do
          plan = create(:creas_strategy_plan, brand: brand, month: '2025-8')
          result = presenter.current_plan_json
          expect(result).to include(plan.strategy_name)
        end
      end
    end

    context 'with plan that has content items' do
      let!(:plan) { create(:creas_strategy_plan, brand: brand, month: '2025-08') }
      let!(:content_item) do
        create(:creas_content_item,
               creas_strategy_plan: plan,
               user: user,
               brand: brand,
               content_id: 'test-content-1',
               content_name: 'Test Content',
               status: 'draft',
               platform: 'instagram',
               content_type: 'reel',
               week: 1,
               pilar: 'C',
               post_description: 'Test description',
               scheduled_day: 'Monday',
               template: 'solo_avatars',
               text_base: 'Test text',
               hashtags: '#test #content',
               publish_date: Date.new(2025, 8, 15),
               meta: {
                 'visual_notes' => 'Cool visuals',
                 'hook' => 'Amazing hook',
                 'cta' => 'Follow us!'
               })
      end
      let(:params) { { month: '2025-08' } }

      it 'includes formatted content items in JSON' do
        json_result = presenter.current_plan_json
        parsed_result = JSON.parse(json_result)

        expect(parsed_result['content_items']).to be_an(Array)
        expect(parsed_result['content_items'].first).to include(
          'id' => 'test-content-1',
          'title' => 'Test Content',
          'status' => 'draft',
          'platform' => 'Instagram',
          'content_type' => 'Reel',
          'week' => 1,
          'pilar' => 'C',
          'description' => 'Test description',
          'scheduled_day' => 'Monday',
          'template' => 'solo_avatars',
          'text_base' => 'Test text',
          'hashtags' => '#test #content',
          'publish_date' => '2025-08-15',
          'visual_notes' => 'Cool visuals',
          'hook' => 'Amazing hook',
          'cta' => 'Follow us!'
        )
      end

      it 'includes formatted weekly plan with items' do
        json_result = presenter.current_plan_json
        parsed_result = JSON.parse(json_result)

        expect(parsed_result['weekly_plan']).to be_an(Array)
        expect(parsed_result['weekly_plan'].length).to eq(5) # Always 5 weeks

        week1 = parsed_result['weekly_plan'].first
        expect(week1['week']).to eq(1)
        expect(week1['ideas']).to be_an(Array)
        expect(week1['ideas'].first).to include(
          'id' => 'test-content-1',
          'title' => 'Test Content',
          'status' => 'draft',
          'platform' => 'Instagram',
          'type' => 'Reel',
          'pilar' => 'C'
        )
      end
    end

    context 'with plan that has no content items' do
      let!(:plan) { create(:creas_strategy_plan, brand: brand, month: '2025-08') }
      let(:params) { { month: '2025-08' } }

      it 'returns original weekly plan when no content items exist' do
        json_result = presenter.current_plan_json
        parsed_result = JSON.parse(json_result)

        expect(parsed_result['content_items']).to eq([])
        expect(parsed_result['weekly_plan']).to eq(plan.weekly_plan)
      end
    end

    context 'with content items having empty meta' do
      let!(:plan) { create(:creas_strategy_plan, brand: brand, month: '2025-08') }
      let!(:content_item) do
        create(:creas_content_item,
               creas_strategy_plan: plan,
               user: user,
               brand: brand,
               content_id: 'test-content-empty-meta',
               status: 'draft',
               meta: {},
               publish_date: nil)
      end
      let(:params) { { month: '2025-08' } }

      it 'handles empty meta gracefully' do
        json_result = presenter.current_plan_json
        parsed_result = JSON.parse(json_result)

        content_item_data = parsed_result['content_items'].first
        expect(content_item_data['visual_notes']).to be_nil
        expect(content_item_data['hook']).to be_nil
        expect(content_item_data['cta']).to be_nil
        expect(content_item_data['publish_date']).to be_nil
      end
    end
  end

  describe '#current_plan (private method)' do
    let(:presenter) { described_class.new(params, brand: brand) }

    context 'when current_plan is passed during initialization' do
      let!(:passed_plan) { create(:creas_strategy_plan, brand: brand, month: '2024-12') }
      let(:presenter) { described_class.new({}, brand: brand, current_plan: passed_plan) }

      it 'returns the passed plan' do
        expect(presenter.send(:current_plan)).to eq(passed_plan)
      end
    end

    context 'when brand is nil' do
      let(:presenter) { described_class.new({}, brand: nil) }

      it 'returns nil' do
        expect(presenter.send(:current_plan)).to be_nil
      end
    end

    context 'with invalid plan_id parameter' do
      let(:params) { { plan_id: 'invalid-uuid' } }

      it 'returns nil for non-existent plan' do
        expect(presenter.send(:current_plan)).to be_nil
      end
    end

    context 'with invalid month parameter' do
      let(:params) { { month: 'invalid-month' } }

      it 'returns nil for invalid month' do
        expect(presenter.send(:current_plan)).to be_nil
      end
    end

    context 'when exact month match is not found but normalized match exists' do
      let!(:plan) { create(:creas_strategy_plan, brand: brand, month: '2025-08') }
      let(:params) { { month: '2025-8' } }

      it 'finds plan using normalized month format' do
        expect(presenter.send(:current_plan)).to eq(plan)
      end
    end

    context 'when multiple plans exist for the same month' do
      let!(:older_plan) { create(:creas_strategy_plan, brand: brand, month: '2025-08', created_at: 1.day.ago) }
      let!(:newer_plan) { create(:creas_strategy_plan, brand: brand, month: '2025-08', created_at: 1.hour.ago) }
      let(:params) { { month: '2025-08' } }

      it 'returns the most recently created plan' do
        expect(presenter.send(:current_plan)).to eq(newer_plan)
      end
    end
  end

  describe 'private method #safe_month_param' do
    context 'with valid formats' do
      it 'allows YYYY-MM format' do
        presenter = described_class.new({ month: '2025-08' })
        expect(presenter.send(:safe_month_param)).to eq('2025-08')
      end

      it 'allows YYYY-M format' do
        presenter = described_class.new({ month: '2025-8' })
        expect(presenter.send(:safe_month_param)).to eq('2025-8')
      end
    end

    context 'with invalid formats' do
      it 'rejects invalid patterns' do
        presenter = described_class.new({ month: '25-08' })
        expect(presenter.send(:safe_month_param)).to be_nil
      end

      it 'rejects non-string input' do
        presenter = described_class.new({ month: 202508 })
        expect(presenter.send(:safe_month_param)).to be_nil
      end

      it 'rejects nil input' do
        presenter = described_class.new({ month: nil })
        expect(presenter.send(:safe_month_param)).to be_nil
      end
    end
  end

  describe 'private method #format_month_for_display' do
    let(:presenter) { described_class.new({}) }

    it 'formats valid month string' do
      result = presenter.send(:format_month_for_display, '2025-08')
      expect(result).to eq('August 2025')
    end

    it 'handles single digit month' do
      result = presenter.send(:format_month_for_display, '2025-8')
      expect(result).to eq('August 2025')
    end

    it 'returns Invalid Month for nil input' do
      result = presenter.send(:format_month_for_display, nil)
      expect(result).to eq('Invalid Month')
    end

    it 'returns Invalid Month for malformed input' do
      result = presenter.send(:format_month_for_display, 'invalid')
      expect(result).to eq('Invalid Month')
    end

    it 'handles ArgumentError gracefully' do
      result = presenter.send(:format_month_for_display, '2025-13')
      expect(result).to eq('Invalid Month')
    end
  end

  describe 'private method #normalize_month_format' do
    let(:presenter) { described_class.new({}) }

    context 'with single digit month' do
      it 'pads single digit month with zero' do
        result = presenter.send(:normalize_month_format, '2025-8')
        expect(result).to eq('2025-08')
      end
    end

    context 'with double digit month' do
      it 'converts to integer format' do
        result = presenter.send(:normalize_month_format, '2025-08')
        expect(result).to eq('2025-8')
      end
    end

    context 'with invalid format' do
      it 'returns original string for non-matching format' do
        result = presenter.send(:normalize_month_format, 'invalid-format')
        expect(result).to eq('invalid-format')
      end
    end
  end
end
