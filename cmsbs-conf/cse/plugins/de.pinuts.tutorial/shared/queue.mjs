/// <reference path="../../../.vscode.js"/>

import SyncQueue from "@de.pinuts.cmsbs.syncqueue/shared/SyncQueue.es6";

const fn = (payload) => {
    console.error('SyncQueue:', payload);
    return true;
}

export const queue = new SyncQueue(fn)
    .setName('tutorial')
    .register();
