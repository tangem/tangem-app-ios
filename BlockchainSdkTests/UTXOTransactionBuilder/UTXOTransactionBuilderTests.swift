//
//  UTXOTransactionSerializerTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

struct UTXOTransactionSerializerTests {
    @Test
    func legacy() throws {
        // given
        let builder = CommonUTXOTransactionSerializer(version: 1, sequence: .final, signHashType: .bitcoinAll)
        let tx = Transaction(
            amount: Amount(with: .bitcoin, type: .coin, value: 0),
            fee: Fee(Amount(with: .bitcoin, type: .coin, value: 0)),
            sourceAddress: "source",
            destinationAddress: "destination",
            changeAddress: "change",
            contractAddress: nil,
            params: nil
        )
        let publicKey = Data(hexString: "02677dd71d01665229de974005670618568b83f6b1e0809aabb99b1646bdc660bb")
        let sourceScript = UTXOLockingScript(
            data: Data(hex: "76a9147775253a54f9873fe3065877a423e4191057d8b988ac"), type: .p2pkh, spendable: .publicKey(publicKey)
        )
        let destinationScript = UTXOLockingScript(
            data: Data(hex: "76a914041c20c9f7d7e16cb2813da977bc9901a8e7d0d688ac"), type: .p2pkh, spendable: .none
        )

        let utxo = UnspentOutput(
            blockId: 3793801,
            txId: "f303c9828af090314f6ab2dc953c21d93e18aaa7c6f3db6e99437d7658412a59",
            index: 1,
            amount: 186367788
        )

        let preImage = PreImageTransaction(
            inputs: [
                .init(output: utxo, script: sourceScript),
            ],
            outputs: [
                .destination(destinationScript, value: 5000000),
                .change(sourceScript, value: 181092520),
            ],
            fee: .zero // Not used
        )

        let signatures = [SignatureInfo(
            // DER encoded
            signature: Data(hex: "3045022100b9ef66034d8da7cf4be4aa86ac3a8d1a6a941767f9add309a03e15f70a1c9a120220628100fd65c9209a353e3eff108bb2763c129cb7c1254e5b9c546fa942e218a1"),
            publicKey: publicKey,
            hash: Data(hex: "6f19e210333abfc47ba3d8ae04fe2a67cc3e2a9a92178d03a4a92fa5cb2fa6e1")
        )]

        // when
        let hashes = try builder.preImageHashes(transaction: (transaction: tx, preImage: preImage))
        let encoded = try builder.compile(transaction: (transaction: tx, preImage: preImage), signatures: signatures)

        // then
        #expect(hashes.count == 1)
        #expect(hashes[0].hex() == signatures[0].hash.hex())
        #expect(encoded.hex() == "0100000001592a4158767d43996edbf3c6a7aa183ed9213c95dcb26a4f3190f08a82c903f3010000006b483045022100b9ef66034d8da7cf4be4aa86ac3a8d1a6a941767f9add309a03e15f70a1c9a120220628100fd65c9209a353e3eff108bb2763c129cb7c1254e5b9c546fa942e218a1012102677dd71d01665229de974005670618568b83f6b1e0809aabb99b1646bdc660bbffffffff02404b4c00000000001976a914041c20c9f7d7e16cb2813da977bc9901a8e7d0d688aca840cb0a000000001976a9147775253a54f9873fe3065877a423e4191057d8b988ac00000000")
    }

    @Test
    func segwit() throws {
        // given
        let builder = CommonUTXOTransactionSerializer(version: 1, sequence: .zero, signHashType: .bitcoinAll)
        let tx = Transaction(
            amount: Amount(with: .bitcoin, type: .coin, value: 0),
            fee: Fee(Amount(with: .bitcoin, type: .coin, value: 0)),
            sourceAddress: "source",
            destinationAddress: "destination",
            changeAddress: "change",
            contractAddress: nil,
            params: nil
        )
        let publicKey = Data(hexString: "0252b019a84e128ea96413179ee5185a07d5eeb7b4755a29416c1b9b8d92fae3aa")
        let sourceScript = UTXOLockingScript(
            data: Data(hex: "001434b42184b9e9eccfe0143804e797bea8cdf86708"), type: .p2wpkh, spendable: .publicKey(publicKey)
        )
        let destinationScript = UTXOLockingScript(
            data: Data(hex: "0014c75a89f9a522c5c8015f308c74b5275800d2c021"), type: .p2wpkh, spendable: .none
        )

        let utxo = UnspentOutput(
            blockId: 2884691,
            txId: "6d2070d67f32b14a621c1570a14e6c8dde97a8a27d6afafb798ce4d7b2e0eed3",
            index: 1,
            amount: 895441
        )

        let preImage = PreImageTransaction(
            inputs: [
                .init(output: utxo, script: sourceScript),
            ],
            outputs: [
                .destination(destinationScript, value: 10000),
                .change(sourceScript, value: 885300),
            ],
            fee: .zero // Not used
        )

        let signatures = [SignatureInfo(
            // DER encoded
            signature: Data(hex: "304502210083e4312e42a4038972c9b15babac8555c0ea85f28ac61cd77071017beb3de9eb022045d6c2d971d8bb8ace5365377f3631d6775e52ac5aebfb56755df25807758525"),
            publicKey: publicKey,
            hash: Data(hex: "4c8bf2e6acfe0e4621665aae3afc82fc7abbc89154181bc1ad507bdf09b4fd95")
        )]

        // when
        let hashes = try builder.preImageHashes(transaction: (transaction: tx, preImage: preImage))
        let encoded = try builder.compile(transaction: (transaction: tx, preImage: preImage), signatures: signatures)

        // then
        #expect(hashes.count == 1)
        #expect(hashes[0].hex() == signatures[0].hash.hex())
        #expect(encoded.hex() == "01000000000101d3eee0b2d7e48c79fbfa6a7da2a897de8d6c4ea170151c624ab1327fd670206d010000000000000000021027000000000000160014c75a89f9a522c5c8015f308c74b5275800d2c02134820d000000000016001434b42184b9e9eccfe0143804e797bea8cdf867080248304502210083e4312e42a4038972c9b15babac8555c0ea85f28ac61cd77071017beb3de9eb022045d6c2d971d8bb8ace5365377f3631d6775e52ac5aebfb56755df2580775852501210252b019a84e128ea96413179ee5185a07d5eeb7b4755a29416c1b9b8d92fae3aa00000000")
    }

    @Test
    func legacy_withMemo() throws {
        // given
        let builder = CommonUTXOTransactionSerializer(version: 1, sequence: .final, signHashType: .bitcoinAll)

        let txNoMemo = Transaction(
            amount: Amount(with: .bitcoin, type: .coin, value: 0),
            fee: Fee(Amount(with: .bitcoin, type: .coin, value: 0)),
            sourceAddress: "source",
            destinationAddress: "destination",
            changeAddress: "change",
            contractAddress: nil,
            params: nil
        )

        let memo = Data("hi".utf8)
        let txWithMemo = Transaction(
            amount: Amount(with: .bitcoin, type: .coin, value: 0),
            fee: Fee(Amount(with: .bitcoin, type: .coin, value: 0)),
            sourceAddress: "source",
            destinationAddress: "destination",
            changeAddress: "change",
            contractAddress: nil,
            params: BitcoinTransactionParams(memo: memo)
        )

        let publicKey = Data(hexString: "02677dd71d01665229de974005670618568b83f6b1e0809aabb99b1646bdc660bb")
        let sourceScript = UTXOLockingScript(
            data: Data(hex: "76a9147775253a54f9873fe3065877a423e4191057d8b988ac"), type: .p2pkh, spendable: .publicKey(publicKey)
        )
        let destinationScript = UTXOLockingScript(
            data: Data(hex: "76a914041c20c9f7d7e16cb2813da977bc9901a8e7d0d688ac"), type: .p2pkh, spendable: .none
        )

        let utxo = UnspentOutput(
            blockId: 3793801,
            txId: "f303c9828af090314f6ab2dc953c21d93e18aaa7c6f3db6e99437d7658412a59",
            index: 1,
            amount: 186367788
        )

        let preImage = PreImageTransaction(
            inputs: [
                .init(output: utxo, script: sourceScript),
            ],
            outputs: [
                .destination(destinationScript, value: 5000000),
                .change(sourceScript, value: 181092520),
            ],
            fee: .zero // Not used
        )

        let signatures = [SignatureInfo(
            // DER encoded (for non-memo case)
            signature: Data(hex: "3045022100b9ef66034d8da7cf4be4aa86ac3a8d1a6a941767f9add309a03e15f70a1c9a120220628100fd65c9209a353e3eff108bb2763c129cb7c1254e5b9c546fa942e218a1"),
            publicKey: publicKey,
            hash: Data(hex: "6f19e210333abfc47ba3d8ae04fe2a67cc3e2a9a92178d03a4a92fa5cb2fa6e1")
        )]

        // when
        let hashesNoMemo = try builder.preImageHashes(transaction: (transaction: txNoMemo, preImage: preImage))
        let hashesWithMemo = try builder.preImageHashes(transaction: (transaction: txWithMemo, preImage: preImage))
        let encoded = try builder.compile(transaction: (transaction: txWithMemo, preImage: preImage), signatures: signatures)

        // then
        #expect(hashesNoMemo.count == 1)
        #expect(hashesWithMemo.count == 1)
        #expect(hashesWithMemo[0].hex() != hashesNoMemo[0].hex())

        // OP_RETURN output: value=0 + scriptLen=4 + 6a 02 6869
        #expect(encoded.hex().contains("0000000000000000046a026869"))
    }
}
