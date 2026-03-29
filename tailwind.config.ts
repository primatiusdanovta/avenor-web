import type { Config } from 'tailwindcss';

export default {
  content: [
    './resources/views/**/*.{blade.php,vue}',
    './resources/js/**/*.{js,ts,vue}',
  ],
  corePlugins: {
    // Disable Tailwind resets that conflict with AdminLTE
    preflight: false,
  },
  theme: {
    extend: {},
  },
  plugins: [],
} satisfies Config;
