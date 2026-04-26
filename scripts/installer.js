#!/usr/bin/env node

/**
 * Velcord Installer
 * Extracts portable app and installs to user's local programs directory
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync, spawn } = require('child_process');
const zlib = require('zlib');

// Use a simple unzipper without external dependencies
const AdmZip = (() => {
  try {
    return require('adm-zip');
  } catch {
    return null;
  }
})();

const VELCORD_ZIP = path.join(__dirname, '..', '..', 'dist', 'velcord-win-x64.zip');
const INSTALL_DIR = path.join(process.env.LOCALAPPDATA, 'Programs', 'Velcord');
const START_MENU_DIR = path.join(process.env.APPDATA, 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Velcord');

console.log('=== Velcord Installer ===');
console.log('Installing to:', INSTALL_DIR);
console.log('Start Menu:', START_MENU_DIR);

function ensureDir(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

function removeDir(dir) {
  if (fs.existsSync(dir)) {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function extractZip(zipPath, outDir) {
  console.log(`Extracting ${zipPath} to ${outDir}...`);
  
  if (AdmZip) {
    const zip = new AdmZip(zipPath);
    zip.extractAllTo(outDir, true);
  } else {
    // Fallback: use PowerShell
    const psCmd = `[System.IO.Compression.ZipFile]::ExtractToDirectory("${zipPath}", "${outDir}", $true)`;
    try {
      execSync(`powershell -NoProfile -Command "${psCmd}"`, { stdio: 'inherit' });
    } catch (e) {
      console.error('Failed to extract ZIP:', e.message);
      throw e;
    }
  }
  console.log('Extraction complete.');
}

function createShortcuts() {
  console.log('Creating shortcuts...');
  
  // Create Start Menu shortcut
  ensureDir(START_MENU_DIR);
  const exePath = path.join(INSTALL_DIR, 'velcord.exe');
  const lnkPath = path.join(START_MENU_DIR, 'Velcord.lnk');
  
  try {
    const psCmd = `
      $$shell = New-Object -ComObject WScript.Shell
      $$shortcut = $$shell.CreateShortcut("${lnkPath}")
      $$shortcut.TargetPath = "${exePath}"
      $$shortcut.IconLocation = "${exePath}"
      $$shortcut.Save()
      Write-Host "Created Start Menu shortcut"
    `;
    execSync(`powershell -NoProfile -Command "${psCmd}"`, { stdio: 'inherit' });
  } catch (e) {
    console.warn('Failed to create Start Menu shortcut:', e.message);
  }
  
  // Create Desktop shortcut
  const desktopPath = path.join(process.env.USERPROFILE, 'Desktop');
  const desktopLnk = path.join(desktopPath, 'Velcord.lnk');
  try {
    const psCmd = `
      $$shell = New-Object -ComObject WScript.Shell
      $$shortcut = $$shell.CreateShortcut("${desktopLnk}")
      $$shortcut.TargetPath = "${exePath}"
      $$shortcut.IconLocation = "${exePath}"
      $$shortcut.Save()
      Write-Host "Created Desktop shortcut"
    `;
    execSync(`powershell -NoProfile -Command "${psCmd}"`, { stdio: 'inherit' });
  } catch (e) {
    console.warn('Failed to create Desktop shortcut:', e.message);
  }
  
  console.log('Shortcuts created.');
}

function createUninstaller() {
  console.log('Creating uninstaller...');
  const uninstallScript = path.join(INSTALL_DIR, 'uninstall.ps1');
  const uninstallBat = path.join(INSTALL_DIR, 'uninstall.bat');
  
  const psContent = `
$installDir = "${INSTALL_DIR}"
$startMenuDir = "${START_MENU_DIR}"
$desktopLnk = "${path.join(process.env.USERPROFILE, 'Desktop', 'Velcord.lnk')}"

Write-Host "Uninstalling Velcord..."
Remove-Item -Path $installDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $startMenuDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $desktopLnk -Force -ErrorAction SilentlyContinue
Write-Host "Velcord has been uninstalled."
`;
  
  fs.writeFileSync(uninstallScript, psContent, 'utf8');
  
  const batContent = `@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
pause
`;
  
  fs.writeFileSync(uninstallBat, batContent, 'utf8');
  console.log('Uninstaller created.');
}

async function main() {
  try {
    // Check if ZIP exists
    if (!fs.existsSync(VELCORD_ZIP)) {
      console.error(`Error: ${VELCORD_ZIP} not found.`);
      console.error('Please ensure the portable app ZIP is present in dist/');
      process.exit(1);
    }
    
    // Create install directory (remove old if exists)
    if (fs.existsSync(INSTALL_DIR)) {
      console.log('Removing old installation...');
      removeDir(INSTALL_DIR);
    }
    ensureDir(INSTALL_DIR);
    
    // Extract ZIP
    extractZip(VELCORD_ZIP, INSTALL_DIR);
    
    // Create shortcuts
    createShortcuts();
    
    // Create uninstaller
    createUninstaller();
    
    console.log('\n=== Installation Complete ===');
    console.log(`Velcord installed to: ${INSTALL_DIR}`);
    console.log(`Start Menu shortcut: ${path.join(START_MENU_DIR, 'Velcord.lnk')}`);
    console.log(`Desktop shortcut: ${path.join(process.env.USERPROFILE, 'Desktop', 'Velcord.lnk')}`);
    console.log(`To uninstall, run: ${path.join(INSTALL_DIR, 'uninstall.bat')}`);
    console.log('\nYou can now launch Velcord from the Start Menu or Desktop shortcut.');
    process.exit(0);
  } catch (error) {
    console.error('Installation failed:', error.message);
    process.exit(1);
  }
}

main();
