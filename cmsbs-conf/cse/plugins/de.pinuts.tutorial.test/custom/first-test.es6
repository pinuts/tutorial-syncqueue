/// <reference path="../../../.vscode.js"/>

import testCase from '@de.pinuts.cmsbs.testdriver2/shared/testCase.es6';
import assert from '@de.pinuts.cmsbs.testdriver2/shared/assert.es6';
import expect from '@de.pinuts.cmsbs.testdriver2/shared/expect.es6';

testCase('A very first test', (describe, it) => {
    describe('Basics', () => {
        it('should provide a version', () => {
            expect(UM.version).to.exist();
        })

        it('should...')

        it('should also do all the other things...')
    })
})
