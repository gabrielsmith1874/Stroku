import http from "node:http";

const host = "127.0.0.1";
const port = Number(process.env.STROKU_MOCK_PORT ?? 7319);

const manifest = {
    id: "org.stroku.mock-direct",
    version: "1.0.0",
    name: "Stroku Mock Direct Streams",
    description: "Local test fixture for direct and raw torrent stream results.",
    resources: ["stream", "subtitles"],
    types: ["movie", "series"],
    catalogs: [],
};

const genericManifest = {
    id: "org.stroku.mock-generic",
    version: "1.0.0",
    name: "Generic Direct Streams",
    description: "Provider-neutral stream add-on fixture.",
    resources: [
        {
            name: "stream",
            types: ["movie", "series"],
            idPrefixes: ["tt"],
        },
    ],
    types: ["movie", "series"],
    catalogs: [],
};

const streams = {
    streams: [
        {
            name: "[RD+] Mock Direct\n1080p H.264",
            title: "Mock.Movie.2026.1080p.WEB-DL.x264.AAC\n👤 42 💾 8.15 GB ⚙️ mock",
            url: `http://${host}:${port}/media/mock-video.mp4?token=test-token`,
            behaviorHints: {
                bingeGroup: "mock|1080p|BluRay|x264",
                filename: "Mock.Movie.2026.1080p.WEB-DL.x264.AAC.mp4",
                proxyHeaders: {
                    request: {
                        Referer: "https://mock-addon.invalid/",
                        "X-Stroku-Test": "proxy-header",
                    },
                },
            },
        },
        {
            name: "[RD+] Mock Direct\n720p",
            title: "Mock HLS fallback without swarm metadata",
            url: `http://${host}:${port}/media/mock-master.m3u8`,
        },
        {
            name: "Raw torrent result",
            description: "This entry must be filtered out by the Roku client.",
            infoHash: "0123456789abcdef0123456789abcdef01234567",
            fileIdx: 0,
        },
        ...Array.from({ length: 6 }, (_, index) => ({
            name: `[RD+] Mock Direct\n${index + 1}080p Test ${index + 3}`,
            title: `Mock release ${index + 3}\n👤 ${30 - index} 💾 ${index + 2}.0 GB ⚙️ mock`,
            url: `http://${host}:${port}/media/mock-video.mp4?release=${index + 3}`,
        })),
    ],
};

const subtitles = {
    subtitles: [
        {
            id: "mock-eng",
            url: `http://${host}:${port}/subtitles/mock-eng.srt`,
            lang: "eng",
        },
        {
            id: "mock-spa",
            url: `http://${host}:${port}/subtitles/mock-spa.srt`,
            lang: "spa",
        },
    ],
};

function labeledStreams(label) {
    return {
        streams: streams.streams.map((stream, index) => ({
            ...stream,
            name: index === 0 ? `[RD+] Mock Direct\n1080p ${label}` : stream.name,
            title: index === 0 ? `${label}.Correct.Release\n👤 42 💾 8.15 GB ⚙️ mock` : stream.title,
        })),
    };
}

const movieCatalog = {
    metas: [
        {
            id: "tt-mock-movie-1",
            type: "movie",
            name: "Signal Decay",
            poster: "",
            description: "Mock movie for navigation testing.",
            releaseInfo: "2023",
        },
        ...Array.from({ length: 17 }, (_, index) => ({
            id: `tt-mock-movie-${index + 2}`,
            type: "movie",
            name: `Mock Movie ${index + 2}`,
            poster: "",
            description: `Mock movie ${index + 2} for Discover grid testing.`,
            releaseInfo: `${2000 + index}`,
        })),
    ],
};

const seriesCatalog = {
    metas: [
        {
            id: "tt-test-series",
            type: "series",
            name: "Test Series",
            poster: "",
            description: "Mock series for episode navigation testing.",
            releaseInfo: "2026",
        },
    ],
};

const seriesMeta = {
    meta: {
        id: "tt-test-series",
        type: "series",
        name: "Test Series",
        background: "https://picsum.photos/seed/stroku-series/1600/600",
        description:
            "A deterministic mock series used to verify season navigation, episode artwork, descriptions, dates, and stream selection.",
        releaseInfo: "2025-",
        runtime: "52 min",
        imdbRating: "8.7",
        genres: ["Drama", "Mystery", "Sci-Fi"],
        videos: [
            {
                id: "tt-test-series:0:1",
                season: 0,
                episode: 1,
                name: "Behind the Story",
                description: "A short look behind the scenes.",
                released: "2024-12-20T05:00:00Z",
                thumbnail: "https://picsum.photos/seed/stroku-special/520/292",
            },
            {
                id: "tt-test-series:1:1",
                season: 1,
                episode: 1,
                name: "Pilot",
                description: "A new employee discovers that the office is hiding an impossible secret.",
                released: "2025-01-17T05:00:00Z",
                thumbnail: "https://picsum.photos/seed/stroku-episode-1/520/292",
            },
            {
                id: "tt-test-series:1:2",
                season: 1,
                episode: 2,
                name: "Second Episode",
                description: "The team follows a message that was never meant to leave the building.",
                released: "2025-01-24T05:00:00Z",
                thumbnail: "https://picsum.photos/seed/stroku-episode-2/520/292",
            },
            {
                id: "tt-test-series:1:3",
                season: 1,
                episode: 3,
                name: "The Long Hall",
                description: "A routine assignment turns into a search for answers.",
                released: "2025-01-31T05:00:00Z",
                thumbnail: "https://picsum.photos/seed/stroku-episode-3/520/292",
            },
            {
                id: "tt-test-series:1:4",
                season: 1,
                episode: 4,
                name: "Overtime",
                description: "Old loyalties are tested when the team is forced to work late.",
                released: "2025-02-07T05:00:00Z",
                thumbnail: "https://picsum.photos/seed/stroku-episode-4/520/292",
            },
            {
                id: "tt-test-series:2:1",
                season: 2,
                episode: 1,
                name: "Return",
                description: "The team returns to find that everything has changed.",
                released: "2026-01-16T05:00:00Z",
                thumbnail: "https://picsum.photos/seed/stroku-season-2/520/292",
            },
        ],
    },
};

const library = new Map([
    [
        "tt-mock-movie-1",
        {
            _id: "tt-mock-movie-1",
            name: "Signal Decay",
            type: "movie",
            poster: "",
            posterShape: "poster",
            removed: false,
            temp: false,
            _ctime: "2026-06-14T12:00:00.000Z",
            _mtime: "2026-06-14T12:00:00.000Z",
            state: {},
            behaviorHints: {},
        },
    ],
]);

function sendJson(response, body, statusCode = 200) {
    response.writeHead(statusCode, {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Accept, Content-Type",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Content-Type": "application/json",
    });
    response.end(JSON.stringify(body));
}

async function readJson(request) {
    const chunks = [];
    for await (const chunk of request) chunks.push(chunk);
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
}

const server = http.createServer(async (request, response) => {
    const url = new URL(request.url, `http://${host}:${port}`);
    console.log(`${request.method} ${url.pathname}`);

    if (request.method === "OPTIONS") {
        response.writeHead(204, {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Accept, Content-Type",
            "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        });
        response.end();
        return;
    }

    if (url.pathname === "/api/v2/create") {
        sendJson(response, {
            result: {
                success: true,
                code: "TEST",
                link: `http://${host}:${port}/approve/TEST`,
                qrcode: "",
            },
        });
        return;
    }

    if (url.pathname === "/api/v2/read") {
        sendJson(response, { result: { authKey: "mock-stremio-auth-key" } });
        return;
    }

    if (url.pathname === "/api/datastoreGet" && request.method === "POST") {
        const body = await readJson(request);
        if (body.authKey !== "mock-stremio-auth-key") {
            sendJson(response, { error: { code: 1, message: "Invalid auth key" } });
            return;
        }
        sendJson(response, { result: [...library.values()] });
        return;
    }

    if (url.pathname === "/api/datastorePut" && request.method === "POST") {
        const body = await readJson(request);
        if (body.authKey !== "mock-stremio-auth-key") {
            sendJson(response, { error: { code: 1, message: "Invalid auth key" } });
            return;
        }
        for (const item of body.changes ?? []) library.set(item._id, item);
        sendJson(response, { result: { success: true } });
        return;
    }

    if (url.pathname === "/approve/TEST") {
        response.writeHead(200, { "Content-Type": "text/plain" });
        response.end("Mock Stremio link approved automatically.");
        return;
    }

    if (
        url.pathname === "/manifest.json" ||
        url.pathname === "/malformed/manifest.json" ||
        url.pathname === "/torrent-only/manifest.json"
    ) {
        sendJson(response, manifest);
        return;
    }

    if (url.pathname === "/generic/manifest.json") {
        sendJson(response, genericManifest);
        return;
    }

    if (/^\/catalog\/movie\/(top|imdbRating|year)(\/genre=[^/]+)?\.json$/.test(url.pathname)) {
        sendJson(response, movieCatalog);
        return;
    }

    if (/^\/catalog\/series\/(top|imdbRating|year)(\/genre=[^/]+)?\.json$/.test(url.pathname)) {
        sendJson(response, seriesCatalog);
        return;
    }

    if (url.pathname === "/meta/series/tt-test-series.json") {
        sendJson(response, seriesMeta);
        return;
    }

    if (url.pathname === "/stream/series/tt-test-series:1:2.json") {
        await new Promise((resolve) => setTimeout(resolve, 18000));
        sendJson(response, streams);
        return;
    }

    if (url.pathname === "/stream/series/tt-test-series:1:1.json") {
        await new Promise((resolve) => setTimeout(resolve, 3000));
        sendJson(response, labeledStreams("SUPERMAN-STALE"));
        return;
    }

    if (url.pathname === "/stream/series/tt-test-series:1:3.json") {
        sendJson(response, labeledStreams("THE-BOYS-CURRENT"));
        return;
    }

    if (/^\/stream\/(movie|series)\/.+\.json$/.test(url.pathname)) {
        sendJson(response, streams);
        return;
    }

    if (/^\/subtitles\/(movie|series)\/.+\.json$/.test(url.pathname)) {
        sendJson(response, subtitles);
        return;
    }

    if (url.pathname === "/subtitles/mock-eng.srt") {
        response.writeHead(200, { "Content-Type": "application/x-subrip" });
        response.end("1\n00:00:00,000 --> 00:00:04,000\nStroku subtitle test\n");
        return;
    }

    if (url.pathname === "/subtitles/mock-spa.srt") {
        response.writeHead(200, { "Content-Type": "application/x-subrip" });
        response.end("1\n00:00:00,000 --> 00:00:04,000\nPrueba de subtitulos de Stroku\n");
        return;
    }

    if (/^\/generic\/stream\/(movie|series)\/tt.+\.json$/.test(url.pathname)) {
        sendJson(response, {
            streams: [
                {
                    name: "1080p Direct",
                    description: "Provider-neutral direct MP4 stream",
                    url: `http://${host}:${port}/media/mock-video.mp4?addon=generic`,
                },
            ],
        });
        return;
    }

    if (/^\/malformed\/stream\/(movie|series)\/.+\.json$/.test(url.pathname)) {
        response.writeHead(200, {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "application/json",
        });
        response.end("{ malformed");
        return;
    }

    if (/^\/torrent-only\/stream\/(movie|series)\/.+\.json$/.test(url.pathname)) {
        sendJson(response, {
            streams: [streams.streams[2]],
        });
        return;
    }

    if (url.pathname === "/media/mock-video.mp4") {
        console.log(
            `MEDIA_HEADERS referer=${request.headers.referer ?? ""} x-stroku-test=${request.headers["x-stroku-test"] ?? ""}`,
        );
        response.writeHead(302, {
            "Access-Control-Allow-Origin": "*",
            Location: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        });
        response.end();
        return;
    }

    if (url.pathname === "/media/mock-master.m3u8") {
        response.writeHead(302, {
            "Access-Control-Allow-Origin": "*",
            Location: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
        });
        response.end();
        return;
    }

    sendJson(response, { error: "Not found" }, 404);
});

server.listen(port, host, () => {
    console.log(`Mock addon listening at http://${host}:${port}/manifest.json`);
    console.log(`Mock Stremio API listening at http://${host}:${port}/api`);
});
