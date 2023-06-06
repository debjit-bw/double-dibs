let splashTexts = ["Do you have it in you?", "Are you ready?", "Can you beat the odds?"]; // array of splash texts

window.addEventListener('DOMContentLoaded', (event) => {
  // choose a random splash text
  let splashText = splashTexts[Math.floor(Math.random() * splashTexts.length)];
  document.getElementById('splashText').textContent = splashText;

  // hide the splash screen after 3 seconds
  setTimeout(() => {
    document.getElementById('splashScreen').style.display = "none";
  }, 1000);
});

function simulateBlockchainInteraction() {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      // Simulate success or failure state
      let hasWon = Math.random() >= 0.5;

      if (hasWon) {
        resolve("NFT Minted"); // Resolve with the success state and the NFT
      } else {
        reject("Lost"); // Reject with the failure state
      }
    }, 3000); // Adjust the delay time (in milliseconds) to simulate the transaction being finalized on-chain
  });
}

document.querySelector('.cards').addEventListener('click', async function(event) {
    if (event.target.matches('.card')) {
      let loader = document.getElementById('loader');

      // Add loading and shape-changing class to the loader
      loader.classList.add('loading', 'shape-changing');
      
      try {
        let result = await simulateBlockchainInteraction();
  
        if (result === "NFT Minted") {
          revealNFT(true); // Call revealNFT with the parameter indicating success
        }
      } catch (error) {
        revealNFT(false); // Call revealNFT with the parameter indicating failure
      }
    }
});

function revealNFT(hasWon) {
    let loader = document.getElementById('loader');
    let nftImage = document.getElementById('nft-image');

    loader.style.display = 'block'; // Show loader

    setTimeout(function() {
      loader.style.display = 'none'; // Hide loader
      loader.classList.remove('shape-changing'); // Remove loading and shape-changing class from the loader

      if (hasWon) {
        // Show NFT image in the nft pane
        nftImage.style.display = 'block';
      } else {
        // Show failure message in the nft pane
        nftImage.style.display = 'none';
        
      }
    }, 3000); // Adjust the delay time (in milliseconds) for the animation to complete
}