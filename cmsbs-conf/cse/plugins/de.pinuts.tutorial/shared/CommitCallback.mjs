/// <reference path="../../../.vscode.js"/>

class MyCommitCallback extends CommitCallback {
    /**
     * @param {Entry} e 
     */
    preCommit(e) {
        if (e.get('entrytype') == 'customer') {
            console.error('preCommit:', e);
        }
    }

    /**
     * @param {Entry} e 
     */
    postCommit(e) {
        if (e.get('entrytype') == 'customer') {
            console.error('postCommit:', e);
        }
    }

    /**
     * @param {Entry} e 
     */
    preRemove(e) {
        if (e.get('entrytype') == 'customer') {
            console.error('preRemove:', e);
        }
    }
}

CommitCallback.registerCallback(() => new MyCommitCallback());
