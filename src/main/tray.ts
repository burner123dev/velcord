/*
 * Velcord, a custom terminal-styled Discord client
 * Copyright (c) 2025 Vendicated and Velcord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { app, BrowserWindow, Menu, Tray, nativeImage, NativeImage } from "electron";

import { createAboutWindow } from "./about";
import { AppEvents } from "./events";
import { Settings } from "./settings";
import { resolveAssetPath } from "./userAssets";
import { clearData } from "./utils/clearData";
import { downloadVencordFiles } from "./utils/vencordLoader";

let tray: Tray;
let trayVariant: "tray" | "trayUnread" = "tray";

AppEvents.on("userAssetChanged", async asset => {
    if (tray && (asset === "tray" || asset === "trayUnread")) {
        const image = await resolveAssetPath(trayVariant);
        tray.setImage(typeof image === "string" ? image : image);
    }
});

AppEvents.on("setTrayVariant", async variant => {
    if (trayVariant === variant) return;

    trayVariant = variant;
    if (!tray) return;

    const image = await resolveAssetPath(trayVariant);
    tray.setImage(typeof image === "string" ? image : image);
});

export function destroyTray() {
    tray?.destroy();
}

export async function initTray(win: BrowserWindow, setIsQuitting: (val: boolean) => void) {
    const onTrayClick = () => {
        if (Settings.store.clickTrayToShowHide && win.isVisible()) win.hide();
        else win.show();
    };

    const trayMenu = Menu.buildFromTemplate([
        {
            label: "Open",
            click() {
                win.show();
            }
        },
        {
            label: "About",
            click: createAboutWindow
        },
        {
            label: "Repair Velcord",
            async click() {
                await downloadVencordFiles();
                app.relaunch();
                app.quit();
            }
        },
        {
            label: "Reset Velcord",
            async click() {
                await clearData(win);
            }
        },
        {
            type: "separator"
        },
        {
            label: "Restart",
            click() {
                app.relaunch();
                app.quit();
            }
        },
        {
            label: "Quit",
            click() {
                setIsQuitting(true);
                app.quit();
            }
        }
    ]);

    const trayImage = await resolveAssetPath(trayVariant);
    tray = new Tray(typeof trayImage === "string" ? trayImage : trayImage);
    tray.setToolTip("Velcord");
    tray.setContextMenu(trayMenu);
    tray.on("click", onTrayClick);
}
