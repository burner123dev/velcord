/*
 * Velcord, a custom terminal-styled Discord client
 * Copyright (c) 2025 Vendicated and Velcord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { BrowserWindow } from "electron";
import { join, extname } from "path";
import { readFile } from "fs/promises";

import { isPathInDirectory } from "./utils/isPathInDirectory";

const STATIC_DIR = join(__dirname, "..", "..", "static");

function contentTypeFor(path: string) {
    const ext = extname(path).toLowerCase();
    switch (ext) {
        case ".html": return "text/html; charset=utf-8";
        case ".css": return "text/css; charset=utf-8";
        case ".js": return "application/javascript";
        case ".json": return "application/json";
        case ".png": return "image/png";
        case ".jpg":
        case ".jpeg": return "image/jpeg";
        case ".webp": return "image/webp";
        case ".svg": return "image/svg+xml";
        case ".ico": return "image/x-icon";
        default: return "application/octet-stream";
    }
}

export async function handleVesktopStaticProtocol(path: string, req: Request) {
    const normalized = path.replace(/^\/+/, "");
    const fullPath = join(STATIC_DIR, normalized);
    if (!isPathInDirectory(fullPath, STATIC_DIR)) {
        return new Response(null, { status: 404 });
    }

    try {
        const data = await readFile(fullPath);
        const headers: Record<string, string> = { "Content-Type": contentTypeFor(fullPath) };
        return new Response(data, { status: 200, headers });
    } catch (e) {
        return new Response(null, { status: 404 });
    }
}

export function loadView(browserWindow: BrowserWindow, view: string, params?: URLSearchParams) {
    const url = new URL(`velcord://static/views/${view}`);
    if (params) {
        url.search = params.toString();
    }

    return browserWindow.loadURL(url.toString());
}
