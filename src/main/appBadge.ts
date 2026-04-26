/*
 * Vesktop, a desktop app aiming to give you a snappier Discord Experience
 * Copyright (c) 2023 Vendicated and Vencord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { app } from "electron";

import { updateUnityLauncherCount } from "./dbus";
import { AppEvents } from "./events";
import { mainWin } from "./mainWindow";

/**
 * -1 = show unread indicator
 * 0 = clear
 */
export function setBadgeCount(count: number) {
    AppEvents.emit("setTrayVariant", count !== 0 ? "trayUnread" : "tray");

    switch (process.platform) {
        case "linux":
            if (count === -1) count = 0;
            updateUnityLauncherCount(count);
            break;
        case "darwin":
            if (count === 0) {
                app.dock!.setBadge("");
                break;
            }
            app.dock!.setBadge(count === -1 ? "•" : count.toString());
            break;
        case "win32":
            // Windows overlay badge icons have been removed to reduce icon asset bloat.
            break;
    }
}
