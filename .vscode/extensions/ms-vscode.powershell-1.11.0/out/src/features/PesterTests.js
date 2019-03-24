"use strict";
/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const path = require("path");
const vscode = require("vscode");
const Settings = require("../settings");
const utils = require("../utils");
var LaunchType;
(function (LaunchType) {
    LaunchType[LaunchType["Debug"] = 0] = "Debug";
    LaunchType[LaunchType["Run"] = 1] = "Run";
})(LaunchType || (LaunchType = {}));
class PesterTestsFeature {
    constructor(sessionManager) {
        this.sessionManager = sessionManager;
        // File context-menu command - Run Pester Tests
        this.command = vscode.commands.registerCommand("PowerShell.RunPesterTestsFromFile", () => {
            this.launchAllTestsInActiveEditor(LaunchType.Run);
        });
        // File context-menu command - Debug Pester Tests
        this.command = vscode.commands.registerCommand("PowerShell.DebugPesterTestsFromFile", () => {
            this.launchAllTestsInActiveEditor(LaunchType.Debug);
        });
        // This command is provided for usage by PowerShellEditorServices (PSES) only
        this.command = vscode.commands.registerCommand("PowerShell.RunPesterTests", (uriString, runInDebugger, describeBlockName) => {
            this.launchTests(uriString, runInDebugger, describeBlockName);
        });
    }
    dispose() {
        this.command.dispose();
    }
    setLanguageClient(languageClient) {
        this.languageClient = languageClient;
    }
    launchAllTestsInActiveEditor(launchType) {
        const uriString = vscode.window.activeTextEditor.document.uri.toString();
        const launchConfig = this.createLaunchConfig(uriString, launchType);
        this.launch(launchConfig);
    }
    launchTests(uriString, runInDebugger, describeBlockName) {
        return __awaiter(this, void 0, void 0, function* () {
            // PSES passes null for the describeBlockName to signal that it can't evaluate the TestName.
            if (!describeBlockName) {
                const answer = yield vscode.window.showErrorMessage("This Describe block's TestName parameter cannot be evaluated. " +
                    `Would you like to ${runInDebugger ? "debug" : "run"} all the tests in this file?`, "Yes", "No");
                if (answer !== "Yes") {
                    return;
                }
            }
            const launchType = runInDebugger ? LaunchType.Debug : LaunchType.Run;
            const launchConfig = this.createLaunchConfig(uriString, launchType);
            if (describeBlockName) {
                launchConfig.args.push("-TestName");
                launchConfig.args.push(`'${describeBlockName}'`);
            }
            this.launch(launchConfig);
        });
    }
    createLaunchConfig(uriString, launchType) {
        const uri = vscode.Uri.parse(uriString);
        const currentDocument = vscode.window.activeTextEditor.document;
        const settings = Settings.load();
        // Since we pass the script path to PSES in single quotes to avoid issues with PowerShell
        // special chars like & $ @ () [], we do have to double up the interior single quotes.
        const scriptPath = uri.fsPath.replace(/'/g, "''");
        const launchConfig = {
            request: "launch",
            type: "PowerShell",
            name: "PowerShell Launch Pester Tests",
            script: "Invoke-Pester",
            args: [
                "-Script",
                `'${scriptPath}'`,
                "-PesterOption",
                "@{IncludeVSCodeMarker=$true}",
            ],
            internalConsoleOptions: "neverOpen",
            noDebug: (launchType === LaunchType.Run),
            createTemporaryIntegratedConsole: settings.debugging.createTemporaryIntegratedConsole,
            cwd: currentDocument.isUntitled
                ? vscode.workspace.rootPath
                : path.dirname(currentDocument.fileName),
        };
        return launchConfig;
    }
    launch(launchConfig) {
        // Create or show the interactive console
        // TODO #367: Check if "newSession" mode is configured
        vscode.commands.executeCommand("PowerShell.ShowSessionConsole", true);
        // Write out temporary debug session file
        utils.writeSessionFile(utils.getDebugSessionFilePath(), this.sessionManager.getSessionDetails());
        // TODO: Update to handle multiple root workspaces.
        vscode.debug.startDebugging(vscode.workspace.workspaceFolders[0], launchConfig);
    }
}
exports.PesterTestsFeature = PesterTestsFeature;
//# sourceMappingURL=PesterTests.js.map