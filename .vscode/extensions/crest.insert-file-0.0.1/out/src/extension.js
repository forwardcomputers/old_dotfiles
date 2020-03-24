'use strict';
// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
var vscode = require('vscode');
var fs = require('fs');
var path = require('path');
// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
function activate(context) {
    // Use the console to output diagnostic information (console.log) and errors (console.error)
    // This line of code will only be executed once when your extension is activated
    console.log('Congratulations, your extension "insert-file" is now active!');
    // The command has been defined in the package.json file
    // Now provide the implementation of the command with  registerCommand
    // The commandId parameter must match the command field in package.json
    var disposable = vscode.commands.registerCommand('extension.insertFile', function () {
        // The code you place here will be executed every time your command is executed
        vscode.window.showInputBox({ placeHolder: "Please input file path.", prompt: "" }).then(function (text) {
            var filepath = text;
            if (!path.isAbsolute(text)) {
                filepath = vscode.workspace.rootPath + '/' + text;
            }
            fs.readFile(filepath, function (err, data) {
                if (err) {
                    vscode.window.showErrorMessage(err.message);
                    return;
                }
                var editor = vscode.window.activeTextEditor;
                // check if there is no selection
                if (editor.selection.isEmpty) {
                    // the Position object gives you the line and character where the cursor is
                    var position_1 = editor.selection.active;
                    vscode.window.activeTextEditor.edit(function (edit) {
                        edit.insert(position_1, data.toString());
                        vscode.window.showInformationMessage("insert file: " + filepath + " is success.");
                    });
                }
            });
        });
    });
    context.subscriptions.push(disposable);
}
exports.activate = activate;
// this method is called when your extension is deactivated
function deactivate() {
}
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map