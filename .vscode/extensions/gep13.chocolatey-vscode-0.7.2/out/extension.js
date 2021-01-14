"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const chocolateyCli = require("./ChocolateyCliManager");
const chocolateyOps = require("./ChocolateyOperation");
const path = require("path");
const fs = require("fs");
var chocolateyManager;
var installed = false;
function activate() {
    // register Commands
    vscode_1.commands.registerCommand("chocolatey.new", () => execute("new"));
    vscode_1.commands.registerCommand("chocolatey.pack", () => execute("pack"));
    vscode_1.commands.registerCommand("chocolatey.delete", () => deleteNupkgs());
    vscode_1.commands.registerCommand("chocolatey.push", () => execute("push"));
    vscode_1.commands.registerCommand("chocolatey.installTemplates", () => execute("installTemplates"));
}
exports.activate = activate;
function deleteNupkgs() {
    // check if there is an open folder in workspace
    if (vscode_1.workspace.rootPath === undefined) {
        vscode_1.window.showErrorMessage("You have not yet opened a folder.");
        return;
    }
    vscode_1.workspace.findFiles("**/*.nupkg").then((nupkgFiles) => {
        if (nupkgFiles.length === 0) {
            vscode_1.window.showErrorMessage("There are no nupkg files in the current workspace.");
            return;
        }
        let quickPickItems = nupkgFiles.map((filePath) => {
            return {
                label: path.basename(filePath.fsPath),
                description: filePath.fsPath
            };
        });
        if (quickPickItems.length > 1) {
            quickPickItems.unshift({ label: "All nupkg files" });
        }
        vscode_1.window.showQuickPick(quickPickItems, {
            placeHolder: "Available nupkg files..."
        }).then((nupkgSelection) => {
            if (!nupkgSelection) {
                return;
            }
            if (nupkgSelection.label === "All nupkg files") {
                quickPickItems.forEach((quickPickItem) => {
                    if (quickPickItem.label === "All nupkg files") {
                        return;
                    }
                    if (quickPickItem.description && fs.existsSync(quickPickItem.description)) {
                        fs.unlinkSync(quickPickItem.description);
                        console.log("Deleted file: " + quickPickItem.description);
                    }
                });
            }
            else {
                if (nupkgSelection.description && fs.existsSync(nupkgSelection.description)) {
                    fs.unlinkSync(nupkgSelection.description);
                    console.log("Deleted file: " + nupkgSelection.description);
                }
            }
        });
    });
}
function execute(cmd, arg) {
    // check if there is an open folder in workspace
    if (vscode_1.workspace.rootPath === undefined) {
        return vscode_1.window.showErrorMessage("You have not yet opened a folder.");
    }
    if (!chocolateyManager) {
        chocolateyManager = new chocolateyCli.ChocolateyCliManager();
    }
    if (!installed) {
        installed = chocolateyOps.isChocolateyCliInstalled();
    }
    if (!cmd) {
        return;
    }
    // ensure Chocolatey is installed
    if (!installed) {
        return vscode_1.window.showErrorMessage("Chocolatey is not installed");
    }
    // check if there is an open folder in workspace
    if (vscode_1.workspace.rootPath === undefined) {
        return vscode_1.window.showErrorMessage("You have not yet opened a folder.");
    }
    let ecmd = chocolateyManager[cmd];
    if (typeof ecmd === "function") {
        try {
            ecmd.apply(chocolateyManager, arg);
            return;
        }
        catch (e) {
            // well, clearly we didn't call a function
            console.log(e);
            return;
        }
    }
    return;
}
//# sourceMappingURL=extension.js.map