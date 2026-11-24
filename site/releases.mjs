export const repository = "JuanciscoPacketTracer/farther-beyond-3d";
export const releasesUrl = `https://github.com/${repository}/releases`;
const apiUrl = `https://api.github.com/repos/${repository}`;

export function findApk(release) {
  if (!release || release.draft || release.prerelease || !Array.isArray(release.assets)) {
    return null;
  }
  return release.assets.find((asset) =>
    typeof asset.name === "string" &&
    /\.apk$/i.test(asset.name) &&
    asset.state === "uploaded" &&
    Number.isFinite(asset.size) && asset.size > 0 &&
    typeof asset.browser_download_url === "string" &&
    asset.browser_download_url.startsWith(`${releasesUrl}/download/`)
  ) ?? null;
}

async function request(url, fetcher) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 12000);
  try {
    return await fetcher(url, {
      headers: { Accept: "application/vnd.github+json" },
      signal: controller.signal,
      cache: "no-store",
    });
  } finally {
    clearTimeout(timeout);
  }
}

function checkResponse(response) {
  if (response.status === 403 || response.status === 429) {
    throw new Error("GitHub ha limitado las consultas. Intenta más tarde o abre los releases directamente.");
  }
  if (!response.ok) {
    throw new Error(`No se pudieron consultar los releases (HTTP ${response.status}).`);
  }
}

export async function getLatestApk(fetcher = fetch) {
  const latest = await request(`${apiUrl}/releases/latest`, fetcher);
  if (latest.status !== 404) {
    checkResponse(latest);
    const release = await latest.json();
    const asset = findApk(release);
    if (asset) return { release, asset };
  }

  // A newer release may contain no Android build. Search published releases by date.
  let newest = null;
  for (let page = 1; ; page += 1) {
    const response = await request(`${apiUrl}/releases?per_page=100&page=${page}`, fetcher);
    checkResponse(response);
    const releases = await response.json();
    if (!Array.isArray(releases)) {
      throw new Error("GitHub devolvió una lista de releases no válida.");
    }
    const candidates = releases
      .filter((release) => findApk(release))
      .sort((a, b) => Date.parse(b.published_at) - Date.parse(a.published_at));
    if (candidates.length && (!newest || Date.parse(candidates[0].published_at) > Date.parse(newest.published_at))) {
      newest = candidates[0];
    }
    if (!response.headers.get("link")?.includes('rel="next"')) {
      return newest ? { release: newest, asset: findApk(newest) } : null;
    }
  }
}

export function formatSize(bytes) {
  return `${(bytes / (1024 * 1024)).toLocaleString("es", { maximumFractionDigits: 1 })} MB`;
}
