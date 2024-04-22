module.exports = {
  content: [
    './app/views/**/*.{html.erb,html,js}',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.{js,jsx,ts,tsx}',
    './app/assets/stylesheets/**/*.css',
  ],
  plugins: [require("daisyui")],
}
