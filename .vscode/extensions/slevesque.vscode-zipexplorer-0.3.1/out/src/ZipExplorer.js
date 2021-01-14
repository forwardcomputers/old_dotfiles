"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const AdmZip = require("adm-zip");
const mkdirp = require("mkdirp");
const path = require("path");
const ZipNode_1 = require("./ZipNode");
const joinPath = require('path.join');
class ZipRoot {
    constructor(_uri) {
        this._uri = _uri;
        try {
            this._zip = new AdmZip(this._uri.fsPath);
            let files = [];
            this._zip.getEntries()
                .sort((a, b) => a.entryName.localeCompare(b.entryName))
                .forEach(e => {
                files.push(e.entryName);
            });
            this._tree = ZipNode_1.treeFromPaths(files, _uri, path.basename(this._uri.fsPath));
        }
        catch (e) {
            vscode_1.window.showErrorMessage(e.toString());
        }
    }
    getText(filePath) {
        return new Promise((resolve, reject) => {
            try {
                this._zip.readAsTextAsync(filePath, resolve);
            }
            catch (error) {
                reject(error.toString());
            }
        });
    }
    extractTo(entryPath, targetPath) {
        this._zip.extractEntryTo(entryPath, targetPath);
    }
    get sourceUri() {
        return this._uri;
    }
    get label() {
        return this._tree.label;
    }
    get parent() {
        return this._tree.parent;
    }
    get nodes() {
        return this._tree.nodes;
    }
}
exports.ZipRoot = ZipRoot;
class ZipModel {
    constructor() {
        this._zipRoots = [];
    }
    openZip(fileUri) {
        this._zipRoots.push(new ZipRoot(fileUri));
    }
    extractFiles(fileUri, folderUri) {
        const zip = new AdmZip(fileUri.fsPath);
        mkdirp.sync(folderUri.fsPath);
        zip.extractAllTo(folderUri.fsPath);
        vscode_1.window.showInformationMessage('Extraction done!');
    }
    extractFilesAsync(fileUri, folderUri, index = 38) {
        return new Promise((resolve, reject) => {
            const zip = new AdmZip(fileUri.fsPath);
            mkdirp.sync(folderUri.fsPath);
            zip.extractAllToAsync(folderUri.fsPath, false, (error) => __awaiter(this, void 0, void 0, function* () {
                if (error) {
                    vscode_1.window.showErrorMessage(error.toString());
                    reject(error);
                }
                else {
                    vscode_1.window.showInformationMessage('Extraction done!');
                    resolve();
                }
            }));
        });
    }
    extractElement(element, folderUri) {
        const uri = element.sourceUri;
        this._zipRoots.forEach(zip => {
            if (uri.path.startsWith(zip.sourceUri.path)) {
                const filePath = joinPath(element.parent, element.label);
                zip.extractTo(filePath, folderUri.fsPath);
            }
        });
    }
    extractElementAsync(element, folderUri) {
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                this.extractElement(element, folderUri);
                vscode_1.window.showInformationMessage('Extraction done!');
                resolve();
            }, 0);
        });
    }
    get roots() {
        return this._zipRoots;
    }
    getContent(uri) {
        return new Promise((resolve, reject) => {
            this._zipRoots.forEach(zip => {
                if (uri.path.startsWith(zip.sourceUri.path)) {
                    const filePath = uri.path.substr(zip.sourceUri.path.length + 1);
                    resolve(zip.getText(filePath));
                }
            });
        });
    }
}
exports.ZipModel = ZipModel;
class ZipTreeDataProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode_1.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
        this.clear();
    }
    openZip(fileUri) {
        this.model.openZip(fileUri);
        this._onDidChangeTreeData.fire();
    }
    clear() {
        this.model = null;
        this.model = new ZipModel();
        this._onDidChangeTreeData.fire();
    }
    extractFiles(fileUri) {
        let folderUri = vscode_1.Uri.file(path.dirname(fileUri.fsPath));
        var ibo = {
            prompt: "Extract to",
            placeHolder: "file path",
            value: folderUri.fsPath
        };
        vscode_1.window.showInputBox(ibo).then(folderPath => {
            folderUri = vscode_1.Uri.file(folderPath);
            vscode_1.window.withProgress({
                location: vscode_1.ProgressLocation.Window,
                title: 'extracting files to ' + folderUri.fsPath
            }, () => {
                return this.model.extractFilesAsync(fileUri, folderUri);
            });
        });
    }
    extractHere(fileUri) {
        const folderUri = vscode_1.Uri.file(path.dirname(fileUri.fsPath));
        vscode_1.window.withProgress({
            location: vscode_1.ProgressLocation.Window,
            title: 'extracting files to ' + folderUri.fsPath
        }, () => {
            return this.model.extractFilesAsync(fileUri, folderUri);
        });
    }
    extractZip(element) {
        this.extractFiles(element.sourceUri);
    }
    extractElement(element) {
        let folderUri = vscode_1.Uri.file(path.dirname(element.sourceUri.fsPath));
        var ibo = {
            prompt: "Extract to",
            placeHolder: "file path",
            value: folderUri.fsPath
        };
        vscode_1.window.showInputBox(ibo).then(folderPath => {
            folderUri = vscode_1.Uri.file(folderPath);
            vscode_1.window.withProgress({
                location: vscode_1.ProgressLocation.Window,
                title: 'extracting to ' + folderUri.fsPath
            }, () => {
                return this.model.extractElementAsync(element, folderUri);
            });
        });
    }
    getTreeItem(element) {
        const isFile = this.getType(element) === 'file';
        let command = undefined;
        if (isFile) {
            command = {
                command: 'openZipResource',
                arguments: [element.sourceUri.with({
                        scheme: 'zip',
                        path: joinPath(element.sourceUri.path, element.parent, element.label)
                    })],
                title: 'Open Zip Resource'
            };
        }
        return {
            label: element.label,
            collapsibleState: isFile ? void 0 : vscode_1.TreeItemCollapsibleState.Collapsed,
            command: command,
            iconPath: this.getIcon(element),
            contextValue: this.getType(element)
        };
    }
    getIcon(element) {
        const type = this.getType(element);
        return {
            dark: path.join(__filename, '..', '..', '..', 'resources', 'dark', type + '.svg'),
            light: path.join(__filename, '..', '..', '..', 'resources', 'light', type + '.svg')
        };
    }
    getType(element) {
        if (element.parent === null) {
            return 'zip';
        }
        else if (element.label.endsWith('/')) {
            return 'folder';
        }
        else {
            return 'file';
        }
    }
    getChildren(element) {
        if (!element) {
            return this.model.roots;
        }
        return element.nodes;
    }
    provideTextDocumentContent(uri, token) {
        return this.model.getContent(uri);
    }
}
exports.ZipTreeDataProvider = ZipTreeDataProvider;
//# sourceMappingURL=ZipExplorer.js.map