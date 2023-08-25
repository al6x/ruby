# TailwindCSS VS Code Config

Add to VSCode Setting

`"tailwindCSS.experimental.configFile": "/Users/alex/.config/tailwind.config.js"`

use absolute path, it doesn't work with relative path like `~/.config/tailwind.config.js`.

Create `/Users/alex/.config/tailwind.config.js`

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["{keep,ftext}/**/*.{html,js,nim}"],
  theme: {
    extend: {},
  },
  plugins: [
    // require('tailwind-children')
  ],
}
```