'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const ZipExplorer_1 = require("./ZipExplorer");
function activate(context) {
    const zipExplorerProvider = new ZipExplorer_1.ZipTreeDataProvider();
    vscode_1.window.registerTreeDataProvider('zipExplorer', zipExplorerProvider);
    vscode_1.workspace.registerTextDocumentContentProvider('zip', zipExplorerProvider);
    vscode_1.commands.registerCommand('zipexplorer.extractFiles', (uri) => {
        zipExplorerProvider.extractFiles(uri);
    });
    vscode_1.commands.registerCommand('zipexplorer.extractHere', (uri) => {
        zipExplorerProvider.extractHere(uri);
    });
    vscode_1.commands.registerCommand('zipexplorer.extractZip', (element) => {
        zipExplorerProvider.extractZip(element);
    });
    vscode_1.commands.registerCommand('zipexplorer.extractElement', (element) => {
        zipExplorerProvider.extractElement(element);
    });
    vscode_1.commands.registerCommand('zipexplorer.exploreZipFile', (uri) => {
        zipExplorerProvider.openZip(uri);
    });
    vscode_1.commands.registerCommand('zipexplorer.clear', () => {
        zipExplorerProvider.clear();
    });
    vscode_1.commands.registerCommand('openZipResource', (uri) => {
        vscode_1.workspace.openTextDocument(uri).then(document => {
            if (document) {
                vscode_1.window.showTextDocument(document);
            }
        });
    });
}
exports.activate = activate;
function deactivate() {
}
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map