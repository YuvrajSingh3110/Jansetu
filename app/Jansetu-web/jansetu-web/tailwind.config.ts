import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#185FA5',
          dark: '#0C447C',
          light: '#E6F1FB',
        },
        alert: {
          red: '#E24B4A',
          'red-bg': '#FCEBEB',
          'red-text': '#A32D2D',
        },
        warn: {
          amber: '#EF9F27',
          'amber-bg': '#FAEEDA',
          'amber-text': '#633806',
        },
        safe: {
          green: '#1D9E75',
          'green-bg': '#E1F5EE',
          'green-text': '#085041',
        },
        page: '#F5F5F5',
        sidebar: {
          text: '#B5D4F4',
        },
        border: '#E5E5E5',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
      fontSize: {
        '10': '10px',
        '11': '11px',
        '12': '12px',
      },
    },
  },
  plugins: [],
}

export default config
