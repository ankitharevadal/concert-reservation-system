/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        dark: {
          950: '#08090c',
          900: '#0e1017',
          850: '#141720',
          800: '#1c202c',
          700: '#2b3142',
        },
        concert: {
          orange: '#ff5722',
          amber: '#f59e0b',
          flame: '#f97316',
          coral: '#ff6b4a',
        },
      },
    },
  },
  plugins: [],
};
