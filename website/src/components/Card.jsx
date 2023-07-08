// import React from 'react';
import PropTypes from 'prop-types';
import styled from '@emotion/styled';

const CardWrapper = styled.div`
  background: #fff;
  border-radius: 2px;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 300px;
  margin: 1rem;
  position: relative;
  width: 80%;
  box-shadow: 0 3px 6px 0 rgba(0, 0, 0, 0.2);
  cursor: pointer;
`;

const Card = ({ id, onClick }) => (
  <CardWrapper onClick={onClick}>
    <h2>Card {id}</h2>
  </CardWrapper>
);

Card.propTypes = {
  id: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired,
};

export default Card;
