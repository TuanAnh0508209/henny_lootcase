// NUI Messaging and Lootcase Spinning Animation Logic
// For FiveM Lootcase System

/**
 * Initialize NUI communication and lootcase animation
 */
const NUIMessaging = {
  isInitialized: false,
  
  /**
   * Send message to the FiveM backend via NUI
   * @param {string} action - The action type
   * @param {object} data - Data to send
   */
  send: function(action, data) {
    fetch(`https://${GetParentResourceName()}/` + action, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data)
    }).then(response => response.json()).catch(error => console.error('NUI Error:', error));
  },

  /**
   * Register event listener from backend
   * @param {string} event - Event name
   * @param {function} callback - Callback function
   */
  on: function(event, callback) {
    window.addEventListener('message', function(event) {
      if (event.data.type === event) {
        callback(event.data);
      }
    });
  }
};

/**
 * Lootcase Spinning Animation Manager
 */
const LootcaseSpinner = {
  isSpinning: false,
  currentRotation: 0,
  spinSpeed: 20, // degrees per frame
  spinDuration: 3000, // milliseconds
  items: [],
  selectedItem: null,
  
  /**
   * Initialize lootcase spinner
   * @param {array} itemList - List of items in the lootcase
   */
  init: function(itemList) {
    this.items = itemList;
    this.setupSpinner();
    this.attachEventListeners();
  },

  /**
   * Setup spinner DOM elements
   */
  setupSpinner: function() {
    const spinnerContainer = document.getElementById('spinner-container');
    if (!spinnerContainer) {
      console.error('Spinner container not found');
      return;
    }
    
    const itemCount = this.items.length;
    const itemAngle = 360 / itemCount;
    
    // Create item slots
    this.items.forEach((item, index) => {
      const itemElement = document.createElement('div');
      itemElement.className = 'spinner-item';
      itemElement.id = `item-${index}`;
      itemElement.textContent = item.label || `Item ${index + 1}`;
      itemElement.style.transform = `rotate(${index * itemAngle}deg) translateY(-150px)`;
      itemElement.dataset.index = index;
      itemElement.dataset.rarity = item.rarity || 'common';
      spinnerContainer.appendChild(itemElement);
    });
  },

  /**
   * Attach event listeners for spinner controls
   */
  attachEventListeners: function() {
    const spinButton = document.getElementById('spin-button');
    if (spinButton) {
      spinButton.addEventListener('click', () => this.spin());
    }

    // Listen for backend commands
    window.addEventListener('message', (event) => {
      const data = event.data;
      if (data.type === 'openLootcase') {
        this.handleOpenLootcase(data);
      } else if (data.type === 'closeLootcase') {
        this.closeLootcase();
      }
    });
  },

  /**
   * Handle opening lootcase from backend
   * @param {object} data - Data from backend
   */
  handleOpenLootcase: function(data) {
    const lootcaseUI = document.getElementById('lootcase-ui');
    if (lootcaseUI) {
      lootcaseUI.style.display = 'flex';
      lootcaseUI.classList.add('active');
    }
    if (data.items) {
      this.items = data.items;
      this.resetSpinner();
      this.setupSpinner();
    }
  },

  /**
   * Reset spinner to initial state
   */
  resetSpinner: function() {
    const spinnerContainer = document.getElementById('spinner-container');
    if (spinnerContainer) {
      spinnerContainer.innerHTML = '';
    }
    this.currentRotation = 0;
    this.isSpinning = false;
    this.selectedItem = null;
  },

  /**
   * Start spinning animation
   */
  spin: function() {
    if (this.isSpinning) {
      console.warn('Already spinning');
      return;
    }

    this.isSpinning = true;
    const spinButton = document.getElementById('spin-button');
    if (spinButton) {
      spinButton.disabled = true;
    }

    // Calculate random final rotation (multiple full rotations + offset)
    const extraRotations = Math.floor(Math.random() * 3) + 3; // 3-5 full rotations
    const itemCount = this.items.length;
    const randomItemIndex = Math.floor(Math.random() * itemCount);
    const itemAngle = 360 / itemCount;
    const finalOffset = randomItemIndex * itemAngle;
    const finalRotation = extraRotations * 360 + finalOffset;

    // Animate spin
    this.animateSpin(finalRotation, randomItemIndex);
  },

  /**
   * Animate the spinning motion
   * @param {number} finalRotation - Final rotation angle in degrees
   * @param {number} selectedIndex - Index of selected item
   */
  animateSpin: function(finalRotation, selectedIndex) {
    const spinnerContainer = document.getElementById('spinner-container');
    const startTime = performance.now();
    const duration = this.spinDuration;
    const startRotation = this.currentRotation;

    const animate = (currentTime) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);

      // Easing function (ease-out cubic)
      const easeProgress = 1 - Math.pow(1 - progress, 3);

      // Calculate current rotation
      const rotation = startRotation + (finalRotation - startRotation) * easeProgress;
      this.currentRotation = rotation;

      // Apply rotation
      if (spinnerContainer) {
        spinnerContainer.style.transform = `rotate(${rotation}deg)`;
      }

      if (progress < 1) {
        requestAnimationFrame(animate);
      } else {
        // Spinning finished
        this.onSpinComplete(selectedIndex);
      }
    };

    requestAnimationFrame(animate);
  },

  /**
   * Handle spin completion
   * @param {number} selectedIndex - Index of winning item
   */
  onSpinComplete: function(selectedIndex) {
    this.isSpinning = false;
    this.selectedItem = this.items[selectedIndex];

    // Highlight selected item
    document.querySelectorAll('.spinner-item').forEach((item, index) => {
      item.classList.remove('selected');
      if (index === selectedIndex) {
        item.classList.add('selected');
      }
    });

    // Show result
    this.showResult(this.selectedItem);

    // Send result to backend
    NUIMessaging.send('spinResult', {
      itemIndex: selectedIndex,
      itemData: this.selectedItem
    });

    // Re-enable spin button after delay
    setTimeout(() => {
      const spinButton = document.getElementById('spin-button');
      if (spinButton) {
        spinButton.disabled = false;
      }
    }, 1500);
  },

  /**
   * Show result UI
   * @param {object} item - Selected item data
   */
  showResult: function(item) {
    const resultBox = document.getElementById('result-box');
    if (resultBox) {
      resultBox.innerHTML = `
        <div class="result-content">
          <div class="result-item-name">${item.label || 'Unknown Item'}</div>
          <div class="result-item-rarity ${item.rarity || 'common'}">${(item.rarity || 'common').toUpperCase()}</div>
          ${item.description ? `<div class="result-item-description">${item.description}</div>` : ''}
        </div>
      `;
      resultBox.classList.add('show');
      
      // Hide after 3 seconds
      setTimeout(() => {
        resultBox.classList.remove('show');
      }, 3000);
    }
  },

  /**
   * Close lootcase UI
   */
  closeLootcase: function() {
    const lootcaseUI = document.getElementById('lootcase-ui');
    if (lootcaseUI) {
      lootcaseUI.classList.remove('active');
      setTimeout(() => {
        lootcaseUI.style.display = 'none';
      }, 300);
    }
    
    // Notify backend
    NUIMessaging.send('closeLootcase', {});
  }
};

/**
 * Initialize on page load
 */
document.addEventListener('DOMContentLoaded', function() {
  console.log('Lootcase UI Loaded');
  
  // Close button handler
  const closeButton = document.getElementById('close-button');
  if (closeButton) {
    closeButton.addEventListener('click', () => LootcaseSpinner.closeLootcase());
  }

  // Listen for ESC key to close
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
      LootcaseSpinner.closeLootcase();
    }
  });

  // Hide UI by default
  const lootcaseUI = document.getElementById('lootcase-ui');
  if (lootcaseUI) {
    lootcaseUI.style.display = 'none';
  }
});

/**
 * Send ready signal to backend
 */
window.addEventListener('load', () => {
  NUIMessaging.send('uiReady', {});
});