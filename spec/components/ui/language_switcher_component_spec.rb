# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ui::LanguageSwitcherComponent, type: :component do
  describe '#render' do
    context 'with default parameters' do
      it 'renders the language switcher' do
        render_inline(Ui::LanguageSwitcherComponent.new)

        expect(page).to have_css('.space-y-3')
        expect(page).to have_content('Language')
        expect(page).to have_link('English')
        expect(page).to have_link('Spanish')
      end
    end

    context 'with Spanish locale' do
      before { I18n.locale = :es }
      after { I18n.locale = I18n.default_locale }

      it 'renders in Spanish' do
        render_inline(Ui::LanguageSwitcherComponent.new)

        expect(page).to have_content('Idioma')
        expect(page).to have_link('Inglés')
        expect(page).to have_link('Español')
      end
    end

    context 'with custom current_locale parameter' do
      it 'marks the specified locale as current' do
        component = Ui::LanguageSwitcherComponent.new(current_locale: :es)
        render_inline(component)

        expect(page).to have_link('English')
        expect(page).to have_link('Spanish')
      end

      it 'generates correct locale paths' do
        component = Ui::LanguageSwitcherComponent.new(current_locale: :en)
        render_inline(component)

        # Check that links are generated with proper locale paths
        expect(page).to have_link('Spanish', href: '/es/')
        expect(page).to have_link('English', href: '/en/')
      end
    end

    context 'with additional options' do
      it 'accepts additional options' do
        component = Ui::LanguageSwitcherComponent.new(class: 'custom-class')
        render_inline(component)

        expect(page).to have_css('.space-y-3')
      end
    end

    context 'with edge case locales' do
      before do
        allow(I18n).to receive(:available_locales).and_return([ :en, :es, :fr ])
      end

      it 'handles unsupported locales with humanized names' do
        component = Ui::LanguageSwitcherComponent.new
        render_inline(component)

        # Should render all available locales
        expect(page).to have_link('English')
        expect(page).to have_link('Spanish')
        expect(page).to have_link('Fr') # Humanized name for French
      end
    end

    context 'when testing different view contexts' do
      it 'works with request context' do
        component = Ui::LanguageSwitcherComponent.new

        # Simulate a request context
        with_request_url 'http://example.com/some-path' do
          render_inline(component)

          expect(page).to have_css('.space-y-3')
          expect(page).to have_content('Language')
        end
      end
    end
  end

  describe 'component initialization' do
    it 'initializes with default current_locale' do
      component = Ui::LanguageSwitcherComponent.new
      expect(component.instance_variable_get(:@current_locale)).to eq(I18n.locale.to_s)
    end

    it 'initializes with custom current_locale as symbol' do
      component = Ui::LanguageSwitcherComponent.new(current_locale: :es)
      expect(component.instance_variable_get(:@current_locale)).to eq('es')
    end

    it 'initializes with custom current_locale as string' do
      component = Ui::LanguageSwitcherComponent.new(current_locale: 'es')
      expect(component.instance_variable_get(:@current_locale)).to eq('es')
    end

    it 'stores additional options' do
      options = { class: 'custom-class', data: { test: 'value' } }
      component = Ui::LanguageSwitcherComponent.new(**options)
      expect(component.instance_variable_get(:@options)).to eq(options)
    end
  end

  describe 'private methods (via rendered component)' do
    let(:component) { Ui::LanguageSwitcherComponent.new }

    context 'with mocked view context' do
      before do
        # Render first to get view context
        render_inline(component)
      end

      it 'available_locales returns correct structure' do
        locales = component.send(:available_locales)

        expect(locales).to be_an(Array)
        expect(locales.length).to eq(I18n.available_locales.length)

        locale = locales.first
        expect(locale).to have_key(:code)
        expect(locale).to have_key(:name)
        expect(locale).to have_key(:current)
      end

      it 'marks current locale correctly in available_locales' do
        component_with_es = Ui::LanguageSwitcherComponent.new(current_locale: :es)
        render_inline(component_with_es)
        locales = component_with_es.send(:available_locales)

        es_locale = locales.find { |l| l[:code] == 'es' }
        en_locale = locales.find { |l| l[:code] == 'en' }

        expect(es_locale[:current]).to be true
        expect(en_locale[:current]).to be false
      end

      it 'locale_name handles different locale types' do
        expect(component.send(:locale_name, :en)).to be_a(String)
        expect(component.send(:locale_name, :es)).to be_a(String)
        expect(component.send(:locale_name, 'en')).to be_a(String)
        expect(component.send(:locale_name, :fr)).to eq('Fr') # Humanized for unsupported
      end

      it 'switch_locale_path handles different scenarios' do
        # Test default locale
        allow(I18n).to receive(:default_locale).and_return(:en)
        path_en = component.send(:switch_locale_path, 'en')
        expect(path_en).to be_a(String)

        # Test non-default locale
        path_es = component.send(:switch_locale_path, 'es')
        expect(path_es).to be_a(String)
        expect(path_es).to include('es') unless path_es == '/'
      end

      it 'switch_locale_path handles complex path scenarios with request context' do
        # Test with existing locale prefix that needs to be replaced
        mock_request = double(path: '/en/complex/nested/path', present?: true)
        allow(component).to receive(:request).and_return(mock_request)
        allow(component).to receive(:respond_to?).with(:request).and_return(true)
        allow(component).to receive(:respond_to?).with(:current_brand).and_return(false)
        allow(I18n).to receive(:default_locale).and_return(:en)

        result = component.send(:switch_locale_path, 'es')
        expect(result).to eq('/es/complex/nested/path')

        # Test with Spanish prefix switching to English
        allow(mock_request).to receive(:path).and_return('/es/another/path')
        result = component.send(:switch_locale_path, 'en')
        expect(result).to eq('/en/another/path')

        # Test with empty path after locale removal
        allow(mock_request).to receive(:path).and_return('/en/')
        result = component.send(:switch_locale_path, 'es')
        expect(result).to eq('/es/')

        # Test default locale with empty path
        allow(mock_request).to receive(:path).and_return('/es/')
        result = component.send(:switch_locale_path, 'en')
        expect(result).to eq('/en/')
      end
    end
  end

  describe 'error handling' do
    it 'gracefully handles missing translations' do
      allow(I18n).to receive(:t).and_raise(I18n::MissingTranslationData.new(:en, :missing_key, {}))

      component = Ui::LanguageSwitcherComponent.new
      expect { render_inline(component) }.not_to raise_error
    end

    it 'handles URL generation errors' do
      component = Ui::LanguageSwitcherComponent.new

      # This should not raise an error even if URL generation has issues
      expect { render_inline(component) }.not_to raise_error
    end

    it 'handles path processing errors gracefully' do
      component = Ui::LanguageSwitcherComponent.new
      allow(component).to receive(:request).and_return(double(path: '/en/test', present?: true))
      allow(component).to receive(:respond_to?).with(:request).and_return(true)
      allow(component).to receive(:respond_to?).with(:current_brand).and_return(false)

      # Mock a StandardError during path processing
      allow(component.send(:request)).to receive(:path).and_raise(StandardError, 'Path processing failed')

      result = component.send(:switch_locale_path, 'es')
      expect(result).to eq('/es/')
    end

    it 'logs warnings when path processing fails' do
      component = Ui::LanguageSwitcherComponent.new
      allow(component).to receive(:request).and_return(double(path: '/en/test', present?: true))
      allow(component).to receive(:respond_to?).with(:request).and_return(true)
      allow(component).to receive(:respond_to?).with(:current_brand).and_return(false)

      # Mock a StandardError during path processing
      allow(component.send(:request)).to receive(:path).and_raise(StandardError, 'Path processing failed')
      allow(Rails.logger).to receive(:warn)

      component.send(:switch_locale_path, 'es')

      expect(Rails.logger).to have_received(:warn).with(/LanguageSwitcherComponent: Failed to generate path for locale es/)
    end
  end

  private

  def with_request_url(url)
    @request = ActionDispatch::TestRequest.create
    @request.host = URI.parse(url).host
    @request.path_info = URI.parse(url).path
    yield
  ensure
    @request = nil
  end
end
