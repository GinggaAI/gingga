require 'rails_helper'
require_relative '../../app/helpers/reels_helper'

RSpec.describe ReelsHelper, type: :helper do
  include ReelsHelper
  describe '#status_icon' do
    it 'returns the correct icon for draft status' do
      expect(status_icon('draft')).to eq('📝')
    end

    it 'returns the correct icon for processing status' do
      expect(status_icon('processing')).to eq('⏳')
    end

    it 'returns the correct icon for completed status' do
      expect(status_icon('completed')).to eq('✅')
    end

    it 'returns the correct icon for failed status' do
      expect(status_icon('failed')).to eq('❌')
    end

    it 'returns the default icon for unknown status' do
      expect(status_icon('unknown')).to eq('📄')
    end

    it 'returns the default icon for nil status' do
      expect(status_icon(nil)).to eq('📄')
    end

    it 'returns the default icon for empty string status' do
      expect(status_icon('')).to eq('📄')
    end

    it 'returns the default icon for whitespace-only status' do
      expect(status_icon('  ')).to eq('📄')
    end
  end

  describe '#status_icon_class' do
    it 'returns the correct CSS class for draft status' do
      expect(status_icon_class('draft')).to eq('bg-gray-100')
    end

    it 'returns the correct CSS class for processing status' do
      expect(status_icon_class('processing')).to eq('bg-yellow-100')
    end

    it 'returns the correct CSS class for completed status' do
      expect(status_icon_class('completed')).to eq('bg-green-100')
    end

    it 'returns the correct CSS class for failed status' do
      expect(status_icon_class('failed')).to eq('bg-red-100')
    end

    it 'returns the default CSS class for unknown status' do
      expect(status_icon_class('unknown')).to eq('bg-gray-100')
    end

    it 'returns the default CSS class for nil status' do
      expect(status_icon_class(nil)).to eq('bg-gray-100')
    end

    it 'returns the default CSS class for empty string status' do
      expect(status_icon_class('')).to eq('bg-gray-100')
    end

    it 'returns the default CSS class for whitespace-only status' do
      expect(status_icon_class('  ')).to eq('bg-gray-100')
    end
  end

  describe '#status_description' do
    it 'returns the correct description for draft status' do
      expect(status_description('draft')).to eq("This reel is saved as a draft and hasn't been generated yet.")
    end

    it 'returns the correct description for processing status' do
      expect(status_description('processing')).to eq("Your video is currently being generated with HeyGen. This usually takes a few minutes.")
    end

    it 'returns the correct description for completed status' do
      expect(status_description('completed')).to eq("Your video has been successfully generated and is ready to view!")
    end

    it 'returns the correct description for failed status' do
      expect(status_description('failed')).to eq("There was an error generating your video. Please try creating a new reel.")
    end

    it 'returns the default description for unknown status' do
      expect(status_description('unknown')).to eq("Unknown status")
    end

    it 'returns the default description for nil status' do
      expect(status_description(nil)).to eq("Unknown status")
    end

    it 'returns the default description for empty string status' do
      expect(status_description('')).to eq("Unknown status")
    end

    it 'returns the default description for whitespace-only status' do
      expect(status_description('  ')).to eq("Unknown status")
    end
  end

  describe '#safe_status_css_class' do
    it 'returns the correct CSS class for allowed draft status' do
      expect(safe_status_css_class('draft')).to eq('bg-gray-100')
    end

    it 'returns the correct CSS class for allowed processing status' do
      expect(safe_status_css_class('processing')).to eq('bg-yellow-100')
    end

    it 'returns the correct CSS class for allowed completed status' do
      expect(safe_status_css_class('completed')).to eq('bg-green-100')
    end

    it 'returns the correct CSS class for allowed failed status' do
      expect(safe_status_css_class('failed')).to eq('bg-red-100')
    end

    it 'returns safe fallback for disallowed status' do
      expect(safe_status_css_class('malicious_status')).to eq('bg-gray-100')
    end

    it 'returns safe fallback for nil status' do
      expect(safe_status_css_class(nil)).to eq('bg-gray-100')
    end

    it 'returns safe fallback for empty string status' do
      expect(safe_status_css_class('')).to eq('bg-gray-100')
    end
  end
end
