/** @type {import('tailwindcss').Config} */
// Tailwind 3 on purpose: v4 output needs Chrome 111+ (cascade layers, oklch),
// which older Fire TV / Android TV WebViews do not have.
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        display: ['Outfit', 'system-ui', 'sans-serif'],
        sans: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
