import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import { WalletProvider } from '@suiet/wallet-kit';
import '@suiet/wallet-kit/style.css';

import {
  SuietWallet,
  SuiWallet,
  EthosWallet,
} from '@suiet/wallet-kit';
// import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <WalletProvider defaultWallets={[
    SuietWallet,
    SuiWallet,
    EthosWallet,
  ]}>
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  </WalletProvider>
)
