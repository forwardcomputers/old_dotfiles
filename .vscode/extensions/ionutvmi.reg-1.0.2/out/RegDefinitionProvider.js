"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
class RegDefinitionProvider {
    provideDefinition(document, position, token) {
        const char = document.lineAt(position.line).text.charAt(position.character);
        if (char != '[' && char != ']')
            return null;
        if (target) {
            return new vscode.Location(document.uri, target);
        }
    }
}
exports.RegDefinitionProvider = RegDefinitionProvider;
//# sourceMappingURL=RegDefinitionProvider.js.map