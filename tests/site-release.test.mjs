import test from "node:test";
import assert from "node:assert/strict";
import { readFile, access } from "node:fs/promises";
import { findApk, formatSize, getLatestApk, releasesUrl } from "../site/releases.mjs";

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
