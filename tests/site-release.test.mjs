import test from "node:test";
import assert from "node:assert/strict";
import { readFile, access } from "node:fs/promises";
import { findApk, formatSize, getLatestApk, releasesUrl } from "../site/releases.mjs";
import { initCarousel } from "../site/carousel.mjs";

const asset = {
  name: "Farther Beyond 3D.apk",
  state: "uploaded",
  size: 327155712,
  browser_download_url: `${releasesUrl}/download/v1.0/Farther.Beyond.3D.apk`,
};
const release = {
  name: "Farther Beyond 3D",
  tag_name: "v1.0",
  published_at: "2026-11-24T08:00:00Z",
  draft: false,
  prerelease: false,
  assets: [asset],
};
const response = (data, status = 200, headers = {}) =>
  new Response(JSON.stringify(data), { status, headers });
const sequence = (...responses) => {
  let index = 0;
  return async () => {
    assert.ok(index < responses.length, "Unexpected API request");
    return responses[index++];
  };
};

test("selects an uploaded APK, not its signature or unrelated assets", () => {
  assert.equal(findApk({ ...release, assets: [{ ...asset, name: "game.apk.idsig" }, asset] }), asset);
  assert.equal(findApk({ ...release, assets: [{ ...asset, name: "GAME.APK" }] }).name, "GAME.APK");
});

test("rejects draft, prerelease, empty, invalid and untrusted downloads", () => {
  for (const value of [
    null, {}, { ...release, draft: true }, { ...release, prerelease: true },
    { ...release, assets: [{ ...asset, size: 0 }] },
    { ...release, assets: [{ ...asset, state: "new" }] },
    { ...release, assets: [{ ...asset, browser_download_url: "javascript:alert(1)" }] },
    { ...release, assets: [{ ...asset, browser_download_url: "https://example.com/game.apk" }] },
  ]) assert.equal(findApk(value), null);
});

test("resolves latest stable APK with the GitHub browser download URL", async () => {
  const result = await getLatestApk(sequence(response(release)));
  assert.deepEqual(result, { release, asset });
});

test("falls back when latest release has no APK and orders by publication date", async () => {
  const older = { ...release, tag_name: "v0.9", published_at: "2026-10-01T00:00:00Z" };
  const result = await getLatestApk(sequence(
    response({ ...release, assets: [] }),
    response([older, { ...release, prerelease: true }, release]),
  ));
  assert.equal(result.release.tag_name, "v1.0");
});

test("handles no releases and releases without Android builds", async () => {
  assert.equal(await getLatestApk(sequence(response({}, 404), response([]))), null);
  assert.equal(await getLatestApk(sequence(response({ ...release, assets: [] }), response([{ ...release, assets: [] }]))), null);
});

test("searches subsequent pages when needed", async () => {
  const result = await getLatestApk(sequence(
    response({}, 404),
    response([{ ...release, assets: [] }], 200, { link: '<https://api.github.com/next>; rel="next"' }),
    response([release]),
  ));
  assert.equal(result.asset.name, asset.name);
});

test("compares publication dates across all pages, not creation order", async () => {
  const older = { ...release, tag_name: "v0.9", published_at: "2026-10-01T00:00:00Z" };
  const result = await getLatestApk(sequence(
    response({ ...release, assets: [] }),
    response([older], 200, { link: '<https://api.github.com/next>; rel="next"' }),
    response([release]),
  ));
  assert.equal(result.release.tag_name, "v1.0");
});

test("reports rate limits, server errors, invalid responses and offline failures", async () => {
  for (const status of [403, 429, 500]) {
    await assert.rejects(getLatestApk(sequence(response({}, status))), status === 500 ? /HTTP 500/ : /limitado/);
  }
  await assert.rejects(getLatestApk(sequence(response({}, 404), response({}))), /no válida/);
  await assert.rejects(getLatestApk(async () => { throw new TypeError("offline"); }), /offline/);
});

test("uses a timeout signal and avoids cached release metadata", async () => {
  await getLatestApk(async (url, options) => {
    assert.match(url, /\/releases\/latest$/);
    assert.ok(options.signal instanceof AbortSignal);
    assert.equal(options.cache, "no-store");
    return response(release);
  });
});

test("formats the APK size in MB", () => {
  assert.equal(formatSize(1048576), "1 MB");
  assert.equal(formatSize(asset.size), "312 MB");
});

test("all local HTML assets exist and URLs work under a Pages project path", async () => {
  const html = await readFile(new URL("../site/index.html", import.meta.url), "utf8");
  assert.match(html, /<html lang="es">/);
  assert.match(html, /<noscript>/);
  assert.match(html, /¿Qué tan lejos<br><em>puedes llegar\?<\/em>/);
  for (const section of ["astronauta", "critters", "gameplay"]) {
    assert.match(html, new RegExp(`id="${section}"`));
  }
  for (const critter of ["Batling", "Xenobat", "Amplet", "Wurmy", "Toadroll"]) {
    assert.ok(html.includes(critter), `Missing bestiary entry: ${critter}`);
  }
  for (const [, path] of html.matchAll(/(?:src|href)="(\.\/[^"]+)"/g)) {
    await access(new URL(`../site/${path}`, import.meta.url));
  }
  const ids = new Set([...html.matchAll(/\bid="([^"]+)"/g)].map((match) => match[1]));
  for (const [, id] of html.matchAll(/href="#([^"]+)"/g)) assert.ok(ids.has(id), `Missing anchor ${id}`);
});

test("provides an accessible tester form and progressive scroll animations", async () => {
  const html = await readFile(new URL("../site/index.html", import.meta.url), "utf8");
  const css = await readFile(new URL("../site/styles.css", import.meta.url), "utf8");
  const app = await readFile(new URL("../site/app.mjs", import.meta.url), "utf8");

  assert.match(html, /href="#testers">Dejar feedback<\/a>/);
  assert.match(html, /id="testers"/);
  assert.match(html, /¿Ya jugaste Farther Beyond\?/);
  assert.match(html, /Este formulario es para quienes ya jugaron/);
  assert.doesNotMatch(html, /Únete al equipo de testers|antes de su lanzamiento/);
  assert.match(html, /src="https:\/\/docs\.google\.com\/forms\/d\/e\/1FAIpQLSeMDuxeJHvVdFgeFpmXtvYVEwtX4QGglcTMwX1cX6vo7ekqyw\/viewform\?embedded=true"/);
  assert.match(html, /title="Formulario para testers de Farther Beyond"/);
  assert.match(html, /Ábrelo directamente en Google Forms/);
  assert.match(html, /data-reveal/);
  assert.match(app, /new IntersectionObserver/);
  assert.match(app, /prefers-reduced-motion/);
  assert.match(css, /\.tester-form-card iframe \{[^}]*width: 100%/);
  assert.match(css, /@media \(prefers-reduced-motion: reduce\)/);
});

test("places the download, post-play survey and repository in that order", async () => {
  const html = await readFile(new URL("../site/index.html", import.meta.url), "utf8");
  const main = html.match(/<main\b[^>]*>([\s\S]*?)<\/main>/)?.[1];
  assert.ok(main, "Missing main content");
  const sections = [...main.matchAll(/<section\b[^>]*\bid="([^"]+)"/g)].map((match) => match[1]);
  assert.deepEqual(sections.slice(-3), ["descargar", "testers", "equipo"]);
  const nav = html.match(/<nav\b[^>]*>([\s\S]*?)<\/nav>/)?.[1];
  assert.ok(nav, "Missing navigation");
  const links = [...nav.matchAll(/href="#([^"]+)"/g)].map((match) => match[1]);
  assert.deepEqual(links.slice(-3), ["descargar", "testers", "equipo"]);
  assert.match(main, /href="https:\/\/github\.com\/JuanciscoPacketTracer\/farther-beyond-3d">Visita el repositorio en GitHub/);
});

test("provides separate Critter and gameplay carousels with a no-JavaScript fallback", async () => {
  const html = await readFile(new URL("../site/index.html", import.meta.url), "utf8");
  const app = await readFile(new URL("../site/app.mjs", import.meta.url), "utf8");
  for (const [section, slideCount] of [["critters", 5], ["gameplay", 3]]) {
    const content = html.match(new RegExp(`<section\\b[^>]*id="${section}"[^>]*>([\\s\\S]*?)</section>`))?.[1];
    assert.ok(content, `Missing ${section} section`);
    assert.equal([...content.matchAll(/\bdata-carousel\b/g)].length, 1);
    assert.equal([...content.matchAll(/\bdata-slide\b/g)].length, slideCount);
    assert.match(content, /class="carousel-controls" hidden/);
    assert.match(content, /data-previous/);
    assert.match(content, /data-next/);
    assert.match(content, /data-rotation/);
    assert.doesNotMatch(content, /data-slide[^>]*\shidden/);
  }
  assert.match(app, /import \{ initCarousel \} from "\.\/carousel\.mjs"/);
});

test("carousel rotates every 10 seconds, wraps, and pauses for interaction", () => {
  class Element {
    listeners = {};
    hidden = false;
    attributes = {};
    classList = { add: (value) => { this.activeClass = value; } };
    addEventListener(type, handler) { this.listeners[type] = handler; }
    setAttribute(name, value) { this.attributes[name] = value; }
    contains(target) { return target === this; }
    fire(type, event = {}) { this.listeners[type](event); }
  }
  const slides = [new Element(), new Element(), new Element()];
  const controls = new Element();
  const previous = new Element();
  const next = new Element();
  const rotation = new Element();
  const count = new Element();
  const carousel = new Element();
  const doc = new Element();
  const motion = new Element();
  motion.matches = false;
  carousel.querySelectorAll = () => slides;
  carousel.querySelector = (selector) => ({
    ".carousel-controls": controls, "[data-previous]": previous, "[data-next]": next,
    "[data-rotation]": rotation, "[data-count]": count,
  })[selector];
  let scheduled;
  const setTimer = (callback, delay) => { scheduled = { callback, delay }; return scheduled; };
  const clearTimer = () => { scheduled = null; };
  initCarousel(carousel, { motion, doc, setTimer, clearTimer });
  assert.deepEqual(slides.map((slide) => slide.hidden), [false, true, true]);
  assert.equal(controls.hidden, false);
  assert.equal(scheduled.delay, 10000);
  scheduled.callback();
  assert.deepEqual(slides.map((slide) => slide.hidden), [true, false, true]);
  assert.equal(count.textContent, "2 / 3");
  carousel.fire("mouseenter");
  assert.equal(scheduled, null);
  carousel.fire("mouseleave");
  assert.equal(scheduled.delay, 10000);
  carousel.fire("focusin");
  assert.equal(scheduled, null);
  previous.fire("click");
  assert.deepEqual(slides.map((slide) => slide.hidden), [false, true, true]);
  assert.equal(count.attributes["aria-live"], "polite");
  previous.fire("click");
  assert.deepEqual(slides.map((slide) => slide.hidden), [true, true, false]);
  carousel.fire("focusout", { relatedTarget: null });
  assert.equal(scheduled, null);
  rotation.fire("click");
  assert.equal(scheduled.delay, 10000);
  doc.hidden = true;
  doc.fire("visibilitychange");
  assert.equal(scheduled, null);
  doc.hidden = false;
  doc.fire("visibilitychange");
  assert.equal(scheduled.delay, 10000);
  motion.fire("change", { matches: true });
  assert.equal(scheduled, null);
  assert.equal(rotation.textContent, "Reanudar rotación automática");
});

test("carousel honors reduced motion and can be navigated manually", () => {
  class Element {
    listeners = {};
    classList = { add() {} };
    addEventListener(type, handler) { this.listeners[type] = handler; }
    setAttribute() {}
  }
  const slides = [new Element(), new Element()];
  const controls = new Element();
  const previous = new Element();
  const next = new Element();
  const rotation = new Element();
  const count = new Element();
  const carousel = new Element();
  const doc = new Element();
  const motion = new Element();
  motion.matches = true;
  carousel.querySelectorAll = () => slides;
  carousel.querySelector = (selector) => ({
    ".carousel-controls": controls, "[data-previous]": previous, "[data-next]": next,
    "[data-rotation]": rotation, "[data-count]": count,
  })[selector];
  let timerCount = 0;
  initCarousel(carousel, { motion, doc, setTimer: () => { timerCount += 1; }, clearTimer() {} });
  assert.equal(timerCount, 0);
  next.listeners.click();
  assert.deepEqual(slides.map((slide) => slide.hidden), [true, false]);
  assert.equal(timerCount, 0);
});
