"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const path = require("path");
function getFullAppPath() {
    if (vscode_1.workspace.rootPath) {
        return path.join(vscode_1.workspace.rootPath, "./");
    }
    return "";
}
exports.getFullAppPath = getFullAppPath;
function getPathToChocolateyConfig() {
    let chocolateyInstallEnvironmentVariable = process.env.ChocolateyInstall;
    if (chocolateyInstallEnvironmentVariable === undefined) {
        // todo: this is really an error condition, and something should be done
        return "";
    }
    return path.join(chocolateyInstallEnvironmentVariable, "config/chocolatey.config");
}
exports.getPathToChocolateyConfig = getPathToChocolateyConfig;
function getPathToChocolateyBin() {
    let chocolateyInstallEnvironmentVariable = process.env.ChocolateyInstall;
    if (chocolateyInstallEnvironmentVariable === undefined) {
        // todo: this is really an error condition, and something should be done
        return "";
    }
    return path.join(chocolateyInstallEnvironmentVariable, "bin/choco.exe");
}
exports.getPathToChocolateyBin = getPathToChocolateyBin;
function getPathToChocolateyTemplates() {
    let chocolateyInstallEnvironmentVariable = process.env.ChocolateyInstall;
    if (chocolateyInstallEnvironmentVariable === undefined) {
        // todo: this is really an error condition, and something should be done
        console.error("Chocolatey installation path could not be found.");
        return "";
    }
    return path.join(chocolateyInstallEnvironmentVariable, "templates");
}
exports.getPathToChocolateyTemplates = getPathToChocolateyTemplates;
//# sourceMappingURL=config.js.map