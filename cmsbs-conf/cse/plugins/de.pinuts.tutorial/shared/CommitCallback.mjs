/// <reference path="../../../.vscode.js"/>

import { queue } from "./queue.mjs";

class MyCommitCallback extends CommitCallback {
    /**
     * @param {Entry} e 
     */
    preCommit(e) {
        if (e.get('entrytype') == 'customer') {
            console.log('preCommit:', e);
        }
    }

    /**
     * @param {Entry} e 
     */
    postCommit(e) {
        if (e.get('entrytype') == 'customer') {
            console.log('postCommit:', e);
            queue.push({ oid: e.oid });
        }
    }

    /**
     * @param {Entry} e 
     */
    preRemove(e) {
        if (e.get('entrytype') == 'customer') {
            console.log('preRemove:', e);
            queue.push({ oid: e.oid });
        }
    }
}

CommitCallback.registerCallback(() => new MyCommitCallback());
