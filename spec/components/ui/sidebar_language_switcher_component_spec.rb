# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::SidebarLanguageSwitcherComponent, type: :component do
  describe '#initialize' do
    it 'initializes with default current_locale' do
      component = described_class.new
      expect(component.instance_variable_get(:@current_locale)).to eq(I18n.locale.to_s)
    end

    it 'initializes with custom current_locale as symbol' do
      component = described_class.new(current_locale: :es)
      expect(component.instance_variable_get(:@current_locale)).to eq('es')
    end

    it 'initializes with custom current_locale as string' do
      component = described_class.new(current_locale: 'es')
      expect(component.instance_variable_get(:@current_locale)).to eq('es')
    end

    it 'stores additional options' do
      options = { class: 'custom-class', data: { test: 'value' } }
      component = described_class.new(**options)
      expect(component.instance_variable_get(:@options)).to eq(options)
    end
  end

  describe '#render' do
    context 'with default parameters' do
      it 'renders the language switcher' do
        render_inline(described_class.new)

        expect(page).to have_css('.relative')
      end
    end

    context 'with Spanish locale' do
      before { I18n.locale = :es }
      after { I18n.locale = I18n.default_locale }

      it 'renders in Spanish' do
        render_inline(described_class.new)

        expect(page).to have_content('Español')
      end
    end
  end

  describe 'private methods' do
    let(:component) { described_class.new }

    before do
      render_inline(component)
    end

    describe '#available_locales' do
      it 'returns array of locale hashes' do
        locales = component.send(:available_locales)

        expect(locales).to be_an(Array)
        expect(locales.length).to eq(I18n.available_locales.length)

        locale = locales.first
        expect(locale).to have_key(:code)
        expect(locale).to have_key(:name)
        expect(locale).to have_key(:current)
      end

      it 'marks current locale correctly' do
        component_with_es = described_class.new(current_locale: :es)
        render_inline(component_with_es)
        locales = component_with_es.send(:available_locales)

        es_locale = locales.find { |l| l[:code] == 'es' }
        en_locale = locales.find { |l| l[:code] == 'en' }

        expect(es_locale[:current]).to be true
        expect(en_locale[:current]).to be false
      end
    end

    describe '#current_locale_info' do
      it 'returns info for current locale' do
        component_en = described_class.new(current_locale: :en)
        render_inline(component_en)
        info = component_en.send(:current_locale_info)

        expect(info[:code]).to eq('en')
        expect(info[:current]).to be true
      end

      it 'returns Spanish locale info when current locale is es' do
        component_es = described_class.new(current_locale: :es)
        render_inline(component_es)
        info = component_es.send(:current_locale_info)

        expect(info[:code]).to eq('es')
        expect(info[:current]).to be true
      end
    end

    describe '#locale_name' do
      it 'returns English for en locale' do
        expect(component.send(:locale_name, :en)).to eq(I18n.t('nav.english'))
      end

      it 'returns Spanish for es locale' do
        expect(component.send(:locale_name, :es)).to eq(I18n.t('nav.spanish'))
      end

      it 'returns humanized name for unsupported locale' do
        expect(component.send(:locale_name, :fr)).to eq('Fr')
      end

      it 'handles string input' do
        expect(component.send(:locale_name, 'en')).to eq(I18n.t('nav.english'))
      end
    end

    describe '#locale_flag' do
      it 'returns US flag for en' do
        expect(component.send(:locale_flag, 'en')).to eq('🇺🇸')
      end

      it 'returns Spanish flag for es' do
        expect(component.send(:locale_flag, 'es')).to eq('🇪🇸')
      end

      it 'returns globe for unsupported locale' do
        expect(component.send(:locale_flag, 'fr')).to eq('🌐')
      end
    end

    describe '#switch_locale_path' do
      context 'without request context' do
        it 'returns default locale path' do
          path = component.send(:switch_locale_path, 'es')
          expect(path).to eq('/es/')
        end
      end

      context 'with request context' do
        it 'handles brand_slug/locale/path format' do
          mock_request = double(path: '/my-brand/en/planning', present?: true)
          allow(component).to receive(:request).and_return(mock_request)
          allow(component).to receive(:respond_to?).with(:request).and_return(true)
          allow(component).to receive(:respond_to?).with(:current_brand).and_return(false)

          result = component.send(:switch_locale_path, 'es')
          expect(result).to eq('/my-brand/es/planning')
        end

        it 'handles brand_slug/locale/ format (empty path)' do
          mock_request = double(path: '/my-brand/en/', present?: true)
          allow(component).to receive(:request).and_return(mock_request)
          allow(component).to receive(:respond_to?).with(:request).and_return(true)
          allow(component).to receive(:respond_to?).with(:current_brand).and_return(false)

          result = component.send(:switch_locale_path, 'es')
          expect(result).to eq('/my-brand/es')
        end

        it 'handles path with current_brand available' do
          mock_request = double(path: '/unknown-path', present?: true)
          mock_brand = double(slug: 'test-brand')
          allow(component).to receive(:request).and_return(mock_request)
          allow(component).to receive(:respond_to?).and_return(true)
          allow(component).to receive(:current_brand).and_return(mock_brand)

          result = component.send(:switch_locale_path, 'es')
          expect(result).to eq('/test-brand/es')
        end

        it 'handles errors gracefully' do
          mock_request = double(path: '/my-brand/en/planning', present?: true)
          allow(component).to receive(:request).and_return(mock_request)
          allow(component).to receive(:respond_to?).with(:request).and_return(true)
          allow(component).to receive(:respond_to?).with(:current_brand).and_return(false)
          allow(mock_request).to receive(:path).and_raise(StandardError, 'Path error')
          allow(Rails.logger).to receive(:warn)

          result = component.send(:switch_locale_path, 'es')
          expect(result).to eq('/es/')
          expect(Rails.logger).to have_received(:warn).with(/SidebarLanguageSwitcherComponent: Failed to generate path/)
        end
      end
    end
  end

  describe 'error handling' do
    it 'handles missing translations gracefully' do
      component = described_class.new

      expect { render_inline(component) }.not_to raise_error
    end

    it 'handles URL generation errors' do
      component = described_class.new

      expect { render_inline(component) }.not_to raise_error
    end
  end
end
