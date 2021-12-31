import 'tailwindcss/tailwind.css'

import dynamic from 'next/dynamic'
const App = dynamic(() => import('./index.js'), { ssr: false })

export default () => <App />