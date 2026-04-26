/*
 * Velcord, a custom terminal-styled Discord client
 * Copyright (c) 2025 Vendicated and Velcord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { app, dialog, nativeImage, NativeImage } from "electron";
import { copyFile, mkdir, rm, readFile } from "fs/promises";
import { join, isAbsolute, extname } from "path";
import { IpcEvents } from "shared/IpcEvents";
import { STATIC_DIR } from "shared/paths";

import { DATA_DIR } from "./constants";
import { AppEvents } from "./events";
import { mainWin } from "./mainWindow";
import { fileExistsAsync } from "./utils/fileExists";
import { handle } from "./utils/ipcWrappers";

const CUSTOMIZABLE_ASSETS = ["splash", "tray", "trayUnread"] as const;
export type UserAssetType = (typeof CUSTOMIZABLE_ASSETS)[number];

const LOGO_PATH = join(__dirname, "..", "..", "..", "logo.png");
const DEFAULT_ASSETS: Record<UserAssetType, string | null> = {
    splash: LOGO_PATH,
    tray: LOGO_PATH,
    trayUnread: LOGO_PATH
};

const UserAssetFolder = join(DATA_DIR, "userAssets");

function resolveDefaultAssetPath(defaultAsset: string | null) {
    if (!defaultAsset) return null;
    return isAbsolute(defaultAsset) ? defaultAsset : join(STATIC_DIR, defaultAsset);
}

export async function resolveAssetPath(asset: UserAssetType): Promise<string | NativeImage> {
    if (!CUSTOMIZABLE_ASSETS.includes(asset)) {
        throw new Error(`Invalid asset: ${asset}`);
    }

    const assetPath = join(UserAssetFolder, asset);
    if (await fileExistsAsync(assetPath)) {
        return assetPath;
    }

    const defaultAsset = DEFAULT_ASSETS[asset];
    const defaultAssetPath = resolveDefaultAssetPath(defaultAsset);
    if (defaultAssetPath && (await fileExistsAsync(defaultAssetPath))) {
        return defaultAssetPath;
    }

    if (asset === "tray" || asset === "trayUnread") {
        return nativeImage.createEmpty();
    }

    if (defaultAssetPath) {
        return defaultAssetPath;
    }

    throw new Error(`No asset available for ${asset}`);
}

export async function handleVesktopAssetsProtocol(path: string, req: Request) {
    const asset = path.slice(1);

    // @ts-expect-error dumb types
    if (!CUSTOMIZABLE_ASSETS.includes(asset)) {
        return new Response(null, { status: 404 });
    }

    try {
        const userPath = join(UserAssetFolder, asset);
        console.log('[vesktop-assets] trying user asset:', userPath);
        if (await fileExistsAsync(userPath)) {
            const data = await readFile(userPath);
            const headers: Record<string, string> = { "Content-Type": contentTypeFor(userPath) };
            return new Response(data, { status: 200, headers });
        }
    } catch (e) {
        console.log('[vesktop-assets] user asset fetch failed:', asset, e && (e as Error).message);
    }

    const defaultAsset = DEFAULT_ASSETS[asset];
    const defaultAssetPath = resolveDefaultAssetPath(defaultAsset);
    if (defaultAssetPath) {
        console.log('[vesktop-assets] default asset path:', defaultAssetPath);
        if (await fileExistsAsync(defaultAssetPath)) {
            try {
                const data = await readFile(defaultAssetPath);
                const headers: Record<string, string> = { "Content-Type": contentTypeFor(defaultAssetPath) };
                console.log('[vesktop-assets] serving default asset for', asset);
                return new Response(data, { status: 200, headers });
            } catch (e) {
                console.log('[vesktop-assets] failed reading default asset:', e && (e as Error).message);
            }
        } else {
            console.log('[vesktop-assets] default asset not found on disk:', defaultAssetPath);
        }
    }

    return new Response(null, { status: 404 });
}

handle(IpcEvents.CHOOSE_USER_ASSET, async (_event, asset: UserAssetType, value?: null) => {
    if (!CUSTOMIZABLE_ASSETS.includes(asset)) {
        throw `Invalid asset: ${asset}`;
    }

    const assetPath = join(UserAssetFolder, asset);

    if (value === null) {
        try {
            await rm(assetPath, { force: true });
            AppEvents.emit("userAssetChanged", asset);
            return "ok";
        } catch (e) {
            console.error(`Failed to remove user asset ${asset}:`, e);
            return "failed";
        }
    }

    const res = await dialog.showOpenDialog(mainWin, {
        properties: ["openFile"],
        title: `Select an image to use as ${asset}`,
        defaultPath: app.getPath("pictures"),
        filters: [
            {
                name: "Images",
                extensions: ["png", "jpg", "jpeg", "webp", "gif", "avif", "svg"]
            }
        ]
    });

    if (res.canceled || !res.filePaths.length) return "cancelled";

    try {
        await mkdir(UserAssetFolder, { recursive: true });
        await copyFile(res.filePaths[0], assetPath);
        AppEvents.emit("userAssetChanged", asset);
        return "ok";
    } catch (e) {
        console.error(`Failed to copy user asset ${asset}:`, e);
        return "failed";
    }
});

function contentTypeFor(path: string) {
    const ext = extname(path).toLowerCase();
    switch (ext) {
        case ".png": return "image/png";
        case ".jpg":
        case ".jpeg": return "image/jpeg";
        case ".webp": return "image/webp";
        case ".svg": return "image/svg+xml";
        case ".ico": return "image/x-icon";
        default: return "application/octet-stream";
    }
}
