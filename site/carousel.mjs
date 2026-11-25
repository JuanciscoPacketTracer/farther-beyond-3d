export function initCarousel(carousel, {
  motion = window.matchMedia("(prefers-reduced-motion: reduce)"),
  doc = document,
  setTimer = setTimeout,
  clearTimer = clearTimeout,
} = {}) {
  const slides = [...carousel.querySelectorAll("[data-slide]")];
  const controls = carousel.querySelector(".carousel-controls");
  const previous = carousel.querySelector("[data-previous]");
  const next = carousel.querySelector("[data-next]");
  const rotation = carousel.querySelector("[data-rotation]");
  const count = carousel.querySelector("[data-count]");
  if (slides.length < 2 || !controls || !previous || !next || !rotation || !count) {
    console.error("No se pudo iniciar el carrusel:", carousel);
    return;
  }

  let index = 0;
  let rotating = !motion.matches;
  let hovered = false;
  let focused = false;
  let timer;

  function showSlide() {
    slides.forEach((slide, slideIndex) => {
      slide.hidden = slideIndex !== index;
    });
    count.textContent = `${index + 1} / ${slides.length}`;
  }

  function updateTimer() {
    clearTimer(timer);
    rotation.textContent = rotating ? "Pausar rotación automática" : "Reanudar rotación automática";
    count.setAttribute("aria-live", rotating ? "off" : "polite");
    if (rotating && !hovered && !focused && !doc.hidden) {
      timer = setTimer(() => {
        index = (index + 1) % slides.length;
        showSlide();
        updateTimer();
      }, 10000);
    }
  }

  function navigate(step) {
    rotating = false;
    index = (index + step + slides.length) % slides.length;
    showSlide();
    updateTimer();
  }

  previous.addEventListener("click", () => navigate(-1));
  next.addEventListener("click", () => navigate(1));
  rotation.addEventListener("click", () => {
    rotating = !rotating;
    updateTimer();
  });
  carousel.addEventListener("mouseenter", () => { hovered = true; updateTimer(); });
  carousel.addEventListener("mouseleave", () => { hovered = false; updateTimer(); });
  carousel.addEventListener("focusin", () => { focused = true; updateTimer(); });
  carousel.addEventListener("focusout", (event) => {
    if (!carousel.contains(event.relatedTarget)) {
      focused = false;
      updateTimer();
    }
  });
  doc.addEventListener("visibilitychange", updateTimer);
  motion.addEventListener("change", (event) => {
    if (event.matches) rotating = false;
    updateTimer();
  });

  showSlide();
  carousel.classList.add("carousel-active");
  controls.hidden = false;
  updateTimer();
}
