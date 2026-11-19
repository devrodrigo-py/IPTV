import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
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
