/*
 * Velcord, a custom terminal-styled Discord client
 * Copyright (c) 2025 Vendicated and Velcord contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

export function stripIndent(strings: TemplateStringsArray, ...values: any[]) {
    const string = String.raw({ raw: strings }, ...values);

    const match = string.match(/^[ \t]*(?=\S)/gm);
    if (!match) return string.trim();

    const minIndent = match.reduce((r, a) => Math.min(r, a.length), Infinity);
    return string.replace(new RegExp(`^[ \\t]{${minIndent}}`, "gm"), "").trim();
}
