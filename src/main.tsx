import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
// Fonts ship with the app: TV boxes may be offline or block Google Fonts.
import '@fontsource/outfit/latin-500.css';
import '@fontsource/outfit/latin-700.css';
import '@fontsource/outfit/latin-800.css';
import '@fontsource/plus-jakarta-sans/latin-400.css';
import '@fontsource/plus-jakarta-sans/latin-600.css';
import '@fontsource/plus-jakarta-sans/latin-700.css';
import './index.css';

/** Older TV WebViews (before Chrome 84) ignore `gap` on flex containers. */
function markFlexGapSupport() {
  const flex = document.createElement('div');
  flex.style.cssText = 'display:flex;flex-direction:column;row-gap:1px;position:absolute;visibility:hidden';
  flex.appendChild(document.createElement('div'));
  flex.appendChild(document.createElement('div'));
  document.body.appendChild(flex);
  const supported = flex.scrollHeight === 1;
  flex.remove();
  if (!supported) document.documentElement.classList.add('no-flex-gap');
}
markFlexGapSupport();

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
