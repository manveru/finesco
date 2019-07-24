// The debounce function receives our function as a parameter
const debounce = (fn) => {
  let frame;

  return (params) => {
    if (frame) { cancelAnimationFrame(frame); }

    frame = requestAnimationFrame(() => {
      fn(params);
    });
  }
};


// Reads out the scroll position and stores it in the data attribute
// so we can use it in our stylesheets
const storeScroll = () => {
  document.documentElement.dataset.scroll = window.scrollY
}

// Listen for new scroll events, here we debounce our `storeScroll` function
document.addEventListener('scroll', debounce(storeScroll), { passive: true })

// Update scroll position for first time
storeScroll()
