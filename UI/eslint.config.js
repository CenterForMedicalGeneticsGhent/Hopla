import eslint from '@eslint/js'
import pluginVue from 'eslint-plugin-vue'
import globals from 'globals'
import tseslint from 'typescript-eslint'

export default tseslint.config(
  {
    ignores: ['dist/**', 'node_modules/**']
  },
  eslint.configs.recommended,
  ...pluginVue.configs['flat/essential'],
  ...tseslint.configs.recommended,
  {
    files: ['**/*.{js,ts,vue}'],
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node
      }
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/no-require-imports': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'no-unused-vars': 'off',
      'vue/multi-word-component-names': 'off'
    }
  },
  {
    files: ['tests/**/*.ts'],
    languageOptions: {
      globals: globals.vitest
    }
  }
)
