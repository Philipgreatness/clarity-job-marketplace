import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create a new job",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        let block = chain.mineBlock([
            Tx.contractCall('job-marketplace', 'create-job', [
                types.utf8("Build a website"),
                types.uint(1000)
            ], wallet1.address)
        ]);
        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Can accept and complete job flow",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const employer = accounts.get('wallet_1')!;
        const worker = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('job-marketplace', 'create-job', [
                types.utf8("Build a website"),
                types.uint(1000)
            ], employer.address),
            Tx.contractCall('job-marketplace', 'accept-job', [
                types.uint(1)
            ], worker.address),
            Tx.contractCall('job-marketplace', 'complete-job', [
                types.uint(1)
            ], worker.address),
            Tx.contractCall('job-marketplace', 'release-payment', [
                types.uint(1)
            ], employer.address)
        ]);

        block.receipts.forEach(receipt => {
            receipt.result.expectOk();
        });
    }
});
