"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const ChocolateyOperation_1 = require("./ChocolateyOperation");
const path = require("path");
const xml2js = require("xml2js");
const fs = require("fs");
const config_1 = require("./config");
class ChocolateyCliManager {
    new() {
        vscode_1.window.showInputBox({
            prompt: "Name for new Chocolatey Package?"
        }).then((result) => {
            if (!result || result === "") {
                return;
            }
            let availableTemplates = this._findPackageTemplates().map((filepath) => {
                return {
                    label: path.basename(filepath),
                };
            });
            if (availableTemplates.length > 0) {
                availableTemplates.unshift({ label: "Default Template" });
                vscode_1.window.showQuickPick(availableTemplates, {
                    placeHolder: "Available templates"
                }).then(template => {
                    let chocoArguments = ["new", result];
                    if (template && template.label !== "Default Template") {
                        chocoArguments.push(`--template-name="'${template.label}'"`);
                    }
                    let newOp = new ChocolateyOperation_1.ChocolateyOperation(chocoArguments);
                    newOp.run();
                });
            }
            else {
                let newOp = new ChocolateyOperation_1.ChocolateyOperation(["new", result]);
                newOp.run();
            }
        });
    }
    pack() {
        vscode_1.workspace.findFiles("**/*.nuspec").then((nuspecFiles) => {
            if (nuspecFiles.length === 0) {
                vscode_1.window.showErrorMessage("There are no nuspec files in the current workspace.");
                return;
            }
            let quickPickItems = nuspecFiles.map((filePath) => {
                return {
                    label: path.basename(filePath.fsPath),
                    description: path.dirname(filePath.fsPath)
                };
            });
            if (quickPickItems.length > 1) {
                quickPickItems.unshift({ label: "All nuspec files" });
            }
            vscode_1.window.showQuickPick(quickPickItems, {
                placeHolder: "Available nuspec files..."
            }).then((nuspecSelection) => {
                if (!nuspecSelection) {
                    return;
                }
                vscode_1.window.showInputBox({
                    prompt: "Additional command arguments?"
                }).then((additionalArguments) => {
                    if (nuspecSelection.label === "All nuspec files") {
                        quickPickItems.forEach((quickPickItem) => {
                            if (!additionalArguments || additionalArguments === "") {
                                additionalArguments = "";
                            }
                            if (quickPickItem.label === "All nuspec files") {
                                return;
                            }
                            let cwd = quickPickItem.description ? quickPickItem.description : "";
                            // tslint:disable-next-line:max-line-length
                            let packOp = new ChocolateyOperation_1.ChocolateyOperation(["pack", quickPickItem.label, additionalArguments], { isOutputChannelVisible: true, currentWorkingDirectory: cwd });
                            packOp.run();
                        });
                    }
                    else {
                        if (!additionalArguments || additionalArguments === "") {
                            additionalArguments = "";
                        }
                        let cwd = nuspecSelection.description ? nuspecSelection.description : "";
                        // tslint:disable-next-line:max-line-length
                        let packOp = new ChocolateyOperation_1.ChocolateyOperation(["pack", nuspecSelection.label, additionalArguments], { isOutputChannelVisible: true, currentWorkingDirectory: cwd });
                        packOp.run();
                    }
                });
            });
        });
    }
    push() {
        // tslint:disable-next-line:max-line-length
        function pushPackage(packages, selectedNupkg, allPackages, source, apikey) {
            vscode_1.window.showInputBox({
                prompt: "Additional command arguments?"
            }).then((additionalArguments) => {
                let chocolateyArguments = [];
                if (source) {
                    chocolateyArguments.push("--source=\"'" + source + "'\"");
                }
                if (apikey) {
                    chocolateyArguments.push("--api-key=\"'" + apikey + "'\"");
                }
                if (!additionalArguments || additionalArguments === "") {
                    additionalArguments = "";
                }
                chocolateyArguments.push(additionalArguments);
                if (allPackages) {
                    packages.forEach((packageToPush) => {
                        if (packageToPush.label === "All nupkg files") {
                            return;
                        }
                        let cwd = packageToPush.description ? packageToPush.description : "";
                        chocolateyArguments.unshift(packageToPush.label);
                        chocolateyArguments.unshift("push");
                        // tslint:disable-next-line:max-line-length
                        let pushOp = new ChocolateyOperation_1.ChocolateyOperation(chocolateyArguments, { isOutputChannelVisible: true, currentWorkingDirectory: cwd });
                        pushOp.run();
                        // remove the first three arguments.  These will be replaced in next iteration
                        chocolateyArguments.splice(0, 3);
                    });
                }
                else {
                    let cwd = selectedNupkg.description ? selectedNupkg.description : "";
                    chocolateyArguments.unshift(selectedNupkg.label);
                    chocolateyArguments.unshift("push");
                    // tslint:disable-next-line:max-line-length
                    let pushOp = new ChocolateyOperation_1.ChocolateyOperation(chocolateyArguments, { isOutputChannelVisible: true, currentWorkingDirectory: cwd });
                    pushOp.run();
                }
            });
        }
        function getCustomSource(quickPickItems, nupkgSelection) {
            // need to get user to specify source
            vscode_1.window.showInputBox({
                prompt: "Source to push package(s) to..."
            }).then((specifiedSource) => {
                vscode_1.window.showInputBox({
                    prompt: "API Key for Source (if required)..."
                }).then((specifiedApiKey) => {
                    if (!specifiedSource) {
                        return;
                    }
                    // tslint:disable-next-line:max-line-length
                    pushPackage(quickPickItems, nupkgSelection, nupkgSelection.label === "All nupkg files", specifiedSource, specifiedApiKey === undefined ? "" : specifiedApiKey);
                });
            });
        }
        vscode_1.workspace.findFiles("**/*.nupkg").then((nupkgFiles) => {
            if (nupkgFiles.length === 0) {
                vscode_1.window.showErrorMessage("There are no nupkg files in the current workspace.");
                return;
            }
            let quickPickItems = nupkgFiles.map((filePath) => {
                return {
                    label: path.basename(filePath.fsPath),
                    description: path.dirname(filePath.fsPath)
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
                let parser = new xml2js.Parser();
                const contents = fs.readFileSync(config_1.getPathToChocolateyConfig()).toString();
                parser.parseString(contents, function (err, result) {
                    if (err) {
                        console.log(err);
                        return;
                    }
                    let sourceQuickPickItems = new Array();
                    if (result.chocolatey.apiKeys[0].apiKeys) {
                        result.chocolatey.apiKeys[0].apiKeys.forEach((apiKey => {
                            sourceQuickPickItems.push({
                                label: apiKey.$.source,
                            });
                        }));
                    }
                    if (sourceQuickPickItems.length === 0) {
                        getCustomSource(quickPickItems, nupkgSelection);
                    }
                    else {
                        if (sourceQuickPickItems.length > 0) {
                            sourceQuickPickItems.unshift({ label: "Use custom source..." });
                        }
                        vscode_1.window.showQuickPick(sourceQuickPickItems, {
                            placeHolder: "Select configured source..."
                        }).then((sourceSelection) => {
                            if (!sourceSelection || !sourceSelection.label) {
                                return;
                            }
                            if (sourceSelection.label === "Use custom source...") {
                                getCustomSource(quickPickItems, nupkgSelection);
                            }
                            else {
                                // tslint:disable-next-line:max-line-length
                                pushPackage(quickPickItems, nupkgSelection, nupkgSelection.label === "All nupkg files", sourceSelection.label, "");
                            }
                        });
                    }
                });
            });
        });
    }
    installTemplates() {
        const config = vscode_1.workspace.getConfiguration("chocolatey").templatePackages;
        let chocoArguments = ["install"];
        config.names.forEach((name) => {
            chocoArguments.push(name);
        });
        chocoArguments.push(`--source="'${config.source}'"`);
        let installTemplatesOp = new ChocolateyOperation_1.ChocolateyOperation(chocoArguments);
        installTemplatesOp.run();
    }
    _findPackageTemplates() {
        let templateDir = config_1.getPathToChocolateyTemplates();
        if (!templateDir || !fs.existsSync(templateDir) || !this._isDirectory(templateDir)) {
            return [];
        }
        return fs.readdirSync(templateDir).map(name => path.join(templateDir, name)).filter(this._isDirectory);
    }
    _isDirectory(path) {
        return fs.lstatSync(path).isDirectory();
    }
}
exports.ChocolateyCliManager = ChocolateyCliManager;
//# sourceMappingURL=ChocolateyCliManager.js.map