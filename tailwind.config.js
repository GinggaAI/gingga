/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.{erb,haml,html,slim}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'gingga-dark': '#0e0c16',
        'gingga-orange': '#f26419',
        'gingga-gold': '#ffc857',
        'gingga-cream': '#f5f1ea',
        'gingga-cyan': '#00c2ff',
        'gingga-violet': '#bb79fc',
      },
      fontFamily: {
        'montserrat': ['Montserrat', 'sans-serif'],
        'poppins': ['Poppins', 'sans-serif'],
      },
    },
  },
  plugins: [],
} 