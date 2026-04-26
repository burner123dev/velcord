/*
 * Vesktop, a desktop app aiming to give you a snappier Discord Experience
 * Copyright (c) 2023 Vendicated and Vencord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import { contextBridge, ipcRenderer, webFrame } from "electron/renderer";

import { IpcEvents } from "../shared/IpcEvents";
import { VesktopNative } from "./VesktopNative";

contextBridge.exposeInMainWorld("VesktopNative", VesktopNative);
contextBridge.exposeInMainWorld("VelcordNative", VesktopNative);

// TODO: remove this legacy workaround once some time has passed
const isSandboxed = typeof __dirname === "undefined";
if (isSandboxed) {
    // While sandboxed, Electron "polyfills" these APIs as local variables.
    // We have to pass them as arguments as they are not global
    Function(
        "require",
        "Buffer",
        "process",
        "clearImmediate",
        "setImmediate",
        ipcRenderer.sendSync(IpcEvents.GET_VENCORD_PRELOAD_SCRIPT)
    )(require, Buffer, process, clearImmediate, setImmediate);
} else {
    require(ipcRenderer.sendSync(IpcEvents.DEPRECATED_GET_VENCORD_PRELOAD_SCRIPT_PATH));
}

webFrame.executeJavaScript(ipcRenderer.sendSync(IpcEvents.GET_VENCORD_RENDERER_SCRIPT));
webFrame.executeJavaScript(ipcRenderer.sendSync(IpcEvents.GET_VESKTOP_RENDERER_SCRIPT));

// Preload-injected titlebar + version badge to survive renderer DOM replacements.
try {
    const version = ipcRenderer.sendSync(IpcEvents.GET_VERSION) || "";
    console.log('[velcord-preload] dispatching inject (version=' + version + ')');

    function __velcord_inject(v: string) {
        if (typeof document === 'undefined') return;
        if (document.getElementById('velcord-titlebar')) return true;
        try {
            const style = document.createElement('style');
            style.id = 'velcord-titlebar-style';
            style.textContent = '#velcord-titlebar{position:fixed;top:0;left:0;right:0;height:36px;display:flex;align-items:center;padding:0 10px;background:rgba(0,0,0,0.6);backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px);border-bottom:1px solid rgba(255,255,255,0.03);z-index:2147483647;color:#8aff8a;font-family:Inconsolata,monospace;font-weight:700;font-size:13px} #velcord-titlebar .logo{height:20px;width:20px;border-radius:2px;margin-right:8px;object-fit:cover;filter:brightness(1)} #velcord-version-badge{margin-left:auto;background:rgba(0,0,0,0.35);padding:4px 8px;border-radius:4px;font-size:12px;color:#7fff7f}';
            (document.head || document.documentElement).appendChild(style);

            const tb = document.createElement('div');
            tb.id = 'velcord-titlebar';
            tb.innerHTML = '<div style="display:flex;align-items:center;gap:6px"><div style="display:flex;align-items:center"><img class="logo" src="velcord://assets/splash" onerror="this.style.display=\'none\'"></div><div>Velcord</div></div><div id="velcord-version-badge">' + v + '</div>';

            try { document.body && document.body.appendChild(tb); } catch (e) { try { document.documentElement.appendChild(tb); } catch (e) { /* ignore */ } }

            const appSelectors = ['#app-mount', '.appMount-3lHmkl', '.app-1q1i1E', '#app'];
            const setPadding = (el: any) => { try { el.style.paddingTop = '36px'; } catch (e) { } };
            for (const s of appSelectors) { const el = document.querySelector(s); if (el) { setPadding(el); break; } }

            return true;
        } catch (e) { return false; }
    }

    // Execute injection first
    webFrame.executeJavaScript('(' + __velcord_inject.toString() + ')(' + JSON.stringify(String(version)) + ');');
    // Then add a persistent observer that re-injects if removed
    const observerWrapper = `(() => {
        try {
            const make = ${__velcord_inject.toString()};
            const mo = new MutationObserver(() => {
                if (!document.getElementById('velcord-titlebar')) {
                    console.log('[velcord-preload][page] titlebar missing, re-injecting');
                    try { make(${JSON.stringify(String(version))}); } catch(e) { console.log('[velcord-preload][page] re-inject failed', e); }
                }
            });
            mo.observe(document.documentElement, { childList: true, subtree: true });
            console.log('[velcord-preload][page] observer-installed');
        } catch(e) { console.log('[velcord-preload][page] observer-install failed', e); }
    })();`;
    webFrame.executeJavaScript(observerWrapper);
    console.log('[velcord-preload] injection dispatched');
} catch (e) { console.log('[velcord-preload] injection failed', e); }
