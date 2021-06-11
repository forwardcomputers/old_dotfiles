module.exports = {
  env: {
    browser: true,
    es2021: true
  },
  plugins: [
    'html',
    'jsdoc'
  ],
  extends: [
    'standard',
    'plugin:jsdoc/recommended'
  ],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module'
  },
  rules: {
    'no-extra-boolean-cast': 'off',
    'no-unneeded-ternary': 'off',
    'array-bracket-spacing': [ 'error', 'always' ],
    'computed-property-spacing': [ 'error', 'always' ],
    'space-in-parens': [ 'error', 'always' ],
    'template-curly-spacing': [ 'error', 'always' ]
  }
}
