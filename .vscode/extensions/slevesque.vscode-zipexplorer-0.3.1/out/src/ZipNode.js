"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const _ = {
    groupBy: require('lodash.groupby')
};
function treeFromPaths(files, sourceUri, label = '') {
    return {
        sourceUri: sourceUri,
        label: label,
        parent: null,
        nodes: childNodesFromPaths(files, '', sourceUri)
    };
}
exports.treeFromPaths = treeFromPaths;
function childNodesFromPaths(files, parent, sourceUri) {
    // Group by first path element
    var groups = _.groupBy(files, file => file.match(/^[^/]*\/?/));
    return Object.keys(groups).map(function (groupKey) {
        const group = groups[groupKey];
        // Is this group explicitly part of the result, or
        // just implicit through its children
        const explicit = group.indexOf(groupKey) >= 0;
        return {
            sourceUri: sourceUri,
            label: groupKey,
            parent: parent,
            nodes: childNodesFromPaths(
            // Remove parent directory from file paths
            group
                .map(node => node.substr(groupKey.length))
                .filter(node => node), 
            // New parent..., normalize to one trailing slash
            parent + groupKey, sourceUri)
        };
    });
}
exports.childNodesFromPaths = childNodesFromPaths;
//# sourceMappingURL=ZipNode.js.map