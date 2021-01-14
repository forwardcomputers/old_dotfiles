"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const cp = require("child_process");
const os = require("os");
const helpers_1 = require("./helpers");
const config_1 = require("./config");
class ChocolateyOperation {
    // tslint:disable-next-line:max-line-length
    constructor(cmd, options = { isOutputChannelVisible: true, currentWorkingDirectory: config_1.getFullAppPath() }) {
        this._spawn = cp.spawn;
        this._stdout = [];
        this._stderr = [];
        this._isOutputChannelVisible = options.isOutputChannelVisible;
        this.cmd = (Array.isArray(cmd)) ? cmd : [cmd];
        this._currentWorkingDirectory = options.currentWorkingDirectory;
        this.created = true;
    }
    getStdout() {
        return this._stdout;
    }
    getStderr() {
        return this._stderr;
    }
    showOutputChannel() {
        if (this._oc) {
            this._oc.show();
            this._isOutputChannelVisible = true;
        }
    }
    hideOutputChannel() {
        if (this._oc) {
            this._oc.dispose();
            this._oc.hide();
            this._isOutputChannelVisible = false;
        }
    }
    kill() {
        if (this._process) {
            this._process.kill();
        }
    }
    run() {
        return new Promise((resolve, reject) => {
            if (!vscode_1.workspace || !vscode_1.workspace.rootPath) {
                return reject();
            }
            let lastOut = "";
            let chocolateyPath = config_1.getPathToChocolateyBin();
            this._oc = vscode_1.window.createOutputChannel(`Chocolatey: ${helpers_1.capitalizeFirstLetter(this.cmd[0])}`);
            if (os.platform() === "win32") {
                let joinedArgs = this.cmd;
                joinedArgs.unshift(chocolateyPath);
                this._process = this._spawn("powershell.exe", joinedArgs, {
                    cwd: this._currentWorkingDirectory ? this._currentWorkingDirectory : config_1.getFullAppPath(),
                    stdio: ["ignore", "pipe", "pipe"]
                });
            }
            else {
                this._process = this._spawn(chocolateyPath, this.cmd, {
                    cwd: this._currentWorkingDirectory ? this._currentWorkingDirectory : config_1.getFullAppPath()
                });
            }
            this._oc.append("Building...");
            if (this._isOutputChannelVisible) {
                this._oc.show();
            }
            this._process.stdout.on("data", (data) => {
                let out = data.toString();
                if (lastOut && out && (lastOut + "." === out)
                    || (lastOut.slice(0, lastOut.length - 1)) === out
                    || (lastOut.slice(0, lastOut.length - 2)) === out
                    || (lastOut.slice(0, lastOut.length - 3)) === out) {
                    lastOut = out;
                    return this._oc.append(".");
                }
                this._oc.appendLine(out);
                this._stdout.push(out);
                lastOut = out;
            });
            this._process.stderr.on("data", (data) => {
                let out = data.toString();
                this._oc.appendLine(out);
                this._stderr.push(out);
            });
            this._process.on("close", (code) => {
                this._oc.appendLine(`Chocolatey ${this.cmd[0]} process exited with code ${code}`);
                resolve({
                    code: code,
                    stderr: this._stderr,
                    stdout: this._stdout
                });
            });
        });
    }
    dispose() {
        if (this._oc) {
            this._oc.dispose();
        }
        if (this._process) {
            this._process.kill();
        }
    }
}
exports.ChocolateyOperation = ChocolateyOperation;
function isChocolateyCliInstalled() {
    let chocolateyBin = config_1.getPathToChocolateyBin();
    try {
        let exec = cp.execSync(`${chocolateyBin} -v`, {
            cwd: config_1.getFullAppPath()
        });
        console.log("Chocolatey is apparently installed");
        console.log(exec.toString());
        return true;
    }
    catch (e) {
        return false;
    }
}
exports.isChocolateyCliInstalled = isChocolateyCliInstalled;
//# sourceMappingURL=ChocolateyOperation.js.map