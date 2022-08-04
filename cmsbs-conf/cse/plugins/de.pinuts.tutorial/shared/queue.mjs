/// <reference path="../../../.vscode.js"/>

import SyncQueue from "@de.pinuts.cmsbs.syncqueue/shared/SyncQueue.es6";
import HttpClientBuilder from "@de.pinuts.http/shared/HttpClientBuilder.es6";

const client = new HttpClientBuilder()
    .build();

const fn = (payload) => {
    console.error('SyncQueue:', payload);

    const e = UM.getEntryByOid(payload.oid);
    let ret;

    if (e) {
        client.post(`http://localhost:8080/tutorial/customer/${e.oid}`)
            .setJsonData({
                oid: e.oid,
                firstname: e.get('firstname'),
                lastname: e.get('lastname'),
                email: e.get('email'),
            })
            .execute()
            .catch(rsp => {
                console.error('HTTP request failed:', rsp);
                ret = `HTTP error: ${rsp.status}`;  // string = recoverable error
            })
            .then(rsp => {
                ret = true;
            });
    } else {
        // Send DELETE request...
    }

    return ret;
}

export const queue = new SyncQueue(fn)
    .setName('tutorial')
    .setMaxRetries(5)
    .setRunOnPush(true)
    .register();
