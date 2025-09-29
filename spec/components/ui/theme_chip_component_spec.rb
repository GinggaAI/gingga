require 'rails_helper'

RSpec.describe Ui::ThemeChipComponent, type: :component do
  describe '#initialize' do
    it 'sets default values correctly' do
      component = described_class.new(theme: 'Technology')

      expect(component.theme).to eq('Technology')
      expect(component.selected).to be false
      expect(component.custom).to be false
      expect(component.removable).to be false
    end

    it 'accepts all initialization parameters' do
      component = described_class.new(
        theme: 'Custom Theme',
        selected: true,
        custom: true,
        removable: true
      )

      expect(component.theme).to eq('Custom Theme')
      expect(component.selected).to be true
      expect(component.custom).to be true
      expect(component.removable).to be true
    end
  end

  describe '#call' do
    context 'when theme is not selected' do
      it 'renders basic chip without checkmark' do
        component = described_class.new(theme: 'Technology')

        render_inline(component)

        expect(page).to have_content('Technology')
        expect(page).not_to have_content('✓')
        expect(page).not_to have_content('×')
        expect(page).to have_css('div[data-theme="Technology"]')
        expect(page).to have_css('div[data-selected="false"]')
      end

      it 'applies correct CSS classes for unselected theme' do
        component = described_class.new(theme: 'Fashion')

        render_inline(component)

        expect(page).to have_css('div.bg-gray-100.text-gray-600.border-gray-300.hover\\:bg-gray-200')
      end
    end

    context 'when theme is selected' do
      context 'and it is not custom' do
        it 'renders chip with checkmark and blue styling' do
          component = described_class.new(theme: 'Technology', selected: true)

          render_inline(component)

          expect(page).to have_content('Technology')
          expect(page).to have_content('✓')
          expect(page).not_to have_content('×')
          expect(page).to have_css('div[data-selected="true"]')
          expect(page).to have_css('div.bg-blue-100.text-blue-800.border-blue-300')
        end
      end

      context 'and it is custom' do
        it 'renders chip with checkmark and green styling' do
          component = described_class.new(
            theme: 'Custom Theme',
            selected: true,
            custom: true
          )

          render_inline(component)

          expect(page).to have_content('Custom Theme')
          expect(page).to have_content('✓')
          expect(page).not_to have_content('×')
          expect(page).to have_css('div.bg-green-100.text-green-800.border-green-300')
        end
      end
    end

    context 'when theme is removable and custom' do
      it 'renders remove button' do
        component = described_class.new(
          theme: 'Custom Theme',
          custom: true,
          removable: true
        )

        render_inline(component)

        expect(page).to have_content('Custom Theme')
        expect(page).to have_content('×')
        expect(page).to have_css('button[data-action="remove-theme"]')
        expect(page).to have_css('button.ml-1.text-xs.hover\\:text-red-600')
      end

      it 'renders with selected state, checkmark and remove button' do
        component = described_class.new(
          theme: 'My Custom Theme',
          selected: true,
          custom: true,
          removable: true
        )

        render_inline(component)

        expect(page).to have_content('My Custom Theme')
        expect(page).to have_content('✓')
        expect(page).to have_content('×')
        expect(page).to have_css('div.bg-green-100.text-green-800.border-green-300')
        expect(page).to have_css('button[data-action="remove-theme"]')
      end
    end

    context 'when theme is removable but not custom' do
      it 'does not render remove button' do
        component = described_class.new(
          theme: 'Technology',
          removable: true,
          custom: false
        )

        render_inline(component)

        expect(page).to have_content('Technology')
        expect(page).not_to have_content('×')
        expect(page).not_to have_css('button[data-action="remove-theme"]')
      end
    end

    context 'when theme is custom but not removable' do
      it 'does not render remove button' do
        component = described_class.new(
          theme: 'Custom Theme',
          custom: true,
          removable: false
        )

        render_inline(component)

        expect(page).to have_content('Custom Theme')
        expect(page).not_to have_content('×')
        expect(page).not_to have_css('button[data-action="remove-theme"]')
      end
    end

    it 'includes all base CSS classes' do
      component = described_class.new(theme: 'Test')

      render_inline(component)

      expect(page).to have_css('div.inline-flex.items-center.gap-2.px-3.py-1\\.5.rounded-full.text-sm.font-medium.cursor-pointer.transition-colors.border.select-none')
    end

    it 'handles special characters in theme names' do
      component = described_class.new(theme: 'Health & Fitness')

      render_inline(component)

      expect(page).to have_content('Health & Fitness')
      expect(page).to have_css('div[data-theme="Health & Fitness"]')
    end

    it 'handles empty theme names' do
      component = described_class.new(theme: '')

      render_inline(component)

      expect(page).to have_css('div[data-theme=""]')
    end
  end

  describe '#css_classes (private method coverage)' do
    it 'generates correct classes for all combinations' do
      # Test unselected theme
      component1 = described_class.new(theme: 'Test')
      render_inline(component1)
      expect(page).to have_css('.bg-gray-100')

      # Test selected non-custom theme
      component2 = described_class.new(theme: 'Test', selected: true)
      render_inline(component2)
      expect(page).to have_css('.bg-blue-100')

      # Test selected custom theme
      component3 = described_class.new(theme: 'Test', selected: true, custom: true)
      render_inline(component3)
      expect(page).to have_css('.bg-green-100')
    end
  end
end
