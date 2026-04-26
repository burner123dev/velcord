/*
 * Velcord, a custom terminal-styled Discord client
 * Copyright (c) 2025 Vendicated and Velcord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { app, protocol } from "electron";

import { handleVesktopAssetsProtocol } from "./userAssets";
import { handleVesktopStaticProtocol } from "./vesktopStatic";

app.whenReady().then(() => {
    const handleStaticRequest = async (req: Electron.ProtocolRequest) => {
        const url = new URL(req.url);
        try {
            console.log('[vesktop-protocol] request:', req.url);
        } catch (e) { }

        switch (url.hostname) {
            case "assets":
                return handleVesktopAssetsProtocol(url.pathname, req);
            case "static":
                return handleVesktopStaticProtocol(url.pathname, req);
            default:
                return new Response(null, { status: 404 });
        }
    };

    protocol.handle("vesktop", handleStaticRequest);
    protocol.handle("velcord", handleStaticRequest);
});
