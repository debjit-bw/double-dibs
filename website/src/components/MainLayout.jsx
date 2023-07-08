// import React from 'react';
import styled from '@emotion/styled';
import { Button } from './Button';
import Card from './Card';
import { useState } from 'react';
import {ConnectButton} from '@suiet/wallet-kit';

const NavBar = styled.nav`
  display: flex;
  justify-content: space-between;
  padding: 1em;
  align-items: center;
  background-color: #5555ff;
  width: 100%;
  height: 5em;
  box-sizing: border-box;
`;

const WalletButton = styled(ConnectButton)`
  display: inline-block;
  padding: 0.5em 1em;
  text-decoration: none;
  background: #668ad8;
  color: #fff;
  border-radius: 3px;
  cursor: pointer;
  &:hover {
    background: #5a7fd5;
  }
  width: 200px;
  box-sizing: border-box;
`;

const LeftContainer = styled.section`
  width: 50%;
  display: flex;
  flex-direction: column;
  justify-content: space-around;
  align-items: center;
  padding: 2em;
`;

const MainContainer = styled.main`
  display: flex;
  height: calc(100vh - 5em - env(safe-area-inset-top));
  box-sizing: border-box;
`;

const RightContainer = styled.section`
  width: 50%;
`;

const PlayButton = styled(Button)`
  margin-top: 2em;
`;

const Modal = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
`;

const ModalContent = styled.div`
  background-color: #fff;
  border-radius: 4px;
  padding: 2rem;
  max-width: 400px;
`;

const CloseButton = styled.button`
  /* Add your desired styles for the close button here */
`;

const MainLayout = () => {
  const handleCardClick = (id) => {
    // Handle the click event based on the card ID
    console.log(`Clicked card with ID: ${id}`);
  };

  const [modalOpen, setModalOpen] = useState(false);

  const handleHowToPlayClick = () => {
    setModalOpen(true);
  };

  const handleCloseClick = () => {
    setModalOpen(false);
  };

  return (
    <div>
      <NavBar>
        <h1>Website Title</h1>
        <WalletButton>Connect wallet</WalletButton>
      </NavBar>
      <MainContainer>
        <LeftContainer>
          <Card id={1} onClick={handleCardClick} />
          <Card id={2} onClick={handleCardClick} />
          <Card id={3} onClick={handleCardClick} />
          <PlayButton onClick={handleHowToPlayClick}>How to play</PlayButton>
          {modalOpen && (
            <Modal>
              <ModalContent>
                <h2>How to Play</h2>
                <p>This is how you play the game...</p>
                <p>Instructions go here...</p>
                <CloseButton onClick={handleCloseClick}>Close</CloseButton>
              </ModalContent>
            </Modal>
          )}
        </LeftContainer>
        <RightContainer>
          {/* Content for the right side goes here */}
        </RightContainer>
      </MainContainer>
    </div>
  );
};

export default MainLayout;
