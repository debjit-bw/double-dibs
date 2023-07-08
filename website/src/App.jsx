// import React from 'react';
import { Global, css } from '@emotion/react';
import MainLayout from './components/MainLayout';

function App() {
  return (
    <div className="App">
      <Global
        styles={css`
          *, *::before, *::after {
            box-sizing: border-box;
          }
          body {
            margin: 0;
            padding: 0;
            overflow-x: hidden;
          }
        `}
      />
      <MainLayout />
    </div>
  );
}

export default App;
