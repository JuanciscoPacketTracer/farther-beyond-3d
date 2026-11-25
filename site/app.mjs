import { formatSize, getLatestApk } from "./releases.mjs";
import { initCarousel } from "./carousel.mjs";

const download = document.querySelector("#apk-download");
const version = document.querySelector("#release-version");
const meta = document.querySelector("#release-meta");
const status = document.querySelector("#release-status");
const retry = document.querySelector("#retry-download");
const releaseLink = document.querySelector("#release-link");

async function loadRelease() {
  download.removeAttribute("href");
  download.setAttribute("aria-disabled", "true");
  retry.hidden = true;
  status.classList.remove("error");
  status.textContent = "Consultando GitHub Releases…";
  version.textContent = "Buscando la última versión…";
  meta.textContent = "La descarga estará disponible cuando se verifique el archivo.";

  try {
    const result = await getLatestApk();
    if (!result) {
      version.textContent = "Próximamente";
      meta.textContent = "Todavía no hay una APK en los releases públicos estables.";
      status.textContent = "La descarga se activará automáticamente cuando el equipo publique una APK.";
      return;
    }
    const { release, asset } = result;
    version.textContent = release.name || release.tag_name;
    const date = new Date(release.published_at);
    const published = Number.isNaN(date.getTime()) ? "" : ` · ${date.toLocaleDateString("es", { dateStyle: "medium" })}`;
    meta.textContent = `${formatSize(asset.size)}${published}`;
    download.href = asset.browser_download_url;
    download.removeAttribute("aria-disabled");
    download.setAttribute("aria-label", `Descargar APK de ${release.tag_name}, ${formatSize(asset.size)}`);
    releaseLink.href = `https://github.com/JuanciscoPacketTracer/farther-beyond-3d/releases/tag/${encodeURIComponent(release.tag_name)}`;
    releaseLink.textContent = "Ver notas de esta versión ↗";
    status.textContent = "APK disponible. El archivo se descarga directamente desde GitHub.";
  } catch (error) {
    console.error("No se pudo cargar la última APK:", error);
    version.textContent = "No pudimos verificar la descarga";
    meta.textContent = "Puedes buscar la APK directamente en GitHub Releases.";
    status.classList.add("error");
    status.textContent = error instanceof Error && error.name !== "AbortError"
      ? error.message
      : "La consulta tardó demasiado o no hay conexión. Reintenta o abre los releases.";
    retry.hidden = false;
  }
}

retry.addEventListener("click", loadRelease);
loadRelease();

document.querySelectorAll("[data-carousel]").forEach((carousel) => initCarousel(carousel));

const revealTargets = document.querySelectorAll("[data-reveal]");
const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

if ("IntersectionObserver" in window && !prefersReducedMotion) {
  const revealObserver = new IntersectionObserver((entries, observer) => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      entry.target.classList.add("is-visible");
      observer.unobserve(entry.target);
    }
  }, { rootMargin: "0px 0px -8% 0px", threshold: 0.12 });

  document.documentElement.classList.add("reveal-ready");
  revealTargets.forEach((target) => revealObserver.observe(target));
}
