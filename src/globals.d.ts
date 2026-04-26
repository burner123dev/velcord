/*
 * Velcord, a custom terminal-styled Discord client
 * Copyright (c) 2023 Vendicated and Velcord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

declare global {
    export var VesktopNative: typeof import("preload/VesktopNative").VesktopNative;
    export var VelcordNative: typeof import("preload/VesktopNative").VesktopNative;

    export var Vesktop: typeof import("renderer/index");
    export var Velcord: typeof import("renderer/index");

    export var VesktopPatchGlobals: any;
    export var VelcordPatchGlobals: any;

    export var IS_DEV: boolean;
}

export {};
