//
//  BitcoinTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

struct BitcoinTransactionTests {
    struct TestUTXOTransactionInputsSorter: UTXOTransactionInputsSorter {
        func sort(inputs: [ScriptUnspentOutput]) -> [ScriptUnspentOutput] {
            // Crutch to sort in the order which was used in the tx below
            inputs.sorted(by: {
                !$0.txId.lexicographicallyPrecedes($1.txId)
            })
        }
    }

    /// https://www.blockchair.com/bitcoin/transaction/1df3c8aa649e1c1b3760685a0fc1ac7b3dd9be7e0ab35f7accf8195737e6caac
    @Test
    func legacyAndDefaultAddressTransaction() throws {
        // given
        let networkParams = BitcoinNetworkParams()
        let pubKey = Data(hexString: "0256e4711ea6bf3309e039ee30b203b18783a8c7c78c68ff2e36acec3c6f51c884")
        let addressService = BitcoinAddressService(networkParams: networkParams)
        let defaultAddress = try addressService.makeAddress(from: pubKey, type: .default)
        let legacyAddress = try addressService.makeAddress(from: pubKey, type: .legacy)

        let unspentOutputManager: UnspentOutputManager = .bitcoin(address: defaultAddress, sorter: TestUTXOTransactionInputsSorter(), isTestnet: false)
        unspentOutputManager.update(
            outputs: [.init(blockId: 891646, txId: "ea8412e1d07d97c14be929c265691b6088cda91f518584c62345d52fb3779b13", index: 0, amount: 1000)],
            for: defaultAddress
        )

        unspentOutputManager.update(
            outputs: [.init(blockId: 891687, txId: "c56265b5baf76572d1cfaedc349c3f8a132b23b7bf573d72414ef93608eb1f8e", index: 0, amount: 1000)],
            for: legacyAddress
        )

        let builder = BitcoinTransactionBuilder(network: networkParams, unspentOutputManager: unspentOutputManager)
        let transaction = Transaction(
            amount: Amount(with: .bitcoin(testnet: false), value: .init(stringValue: "0.00001703")!),
            fee: Fee(.init(with: .bitcoin(testnet: false), value: .init(stringValue: "0.00000297")!), parameters: BitcoinFeeParameters(rate: 1)),
            sourceAddress: defaultAddress.value,
            destinationAddress: "bc1qtsuu4zgsgstnem5hqhuem4707w7tswq25uzml86ffgj57xttc3uqptg999",
            changeAddress: defaultAddress.value
        )

        let signatures = [
            SignatureInfo(
                signature: Data(hexString: "611255ea986b38e90769dad8176b0850b55ab8c0e4ae01bc857eef7253c0c7694a15a870f80be4fcb55af33f38fe2129058ac7025436bdfcee299f7c51db5ba3"),
                publicKey: pubKey,
                hash: Data(hexString: "dbb1b577cb502f97183f60fe3009c24daf1dfa68f89f7477c998f55ccba93aff")
            ),
            SignatureInfo(
                signature: Data(hexString: "9dae8b07d96dd4bd908e567f1f7595fe476ffd6c0d273f604060dc858ba8bebc6fdf3edeb02f1be490b9011923d75f85c9f19df813a3096c3b0bda0c3ffd45bb"),
                publicKey: pubKey,
                hash: Data(hexString: "71efeb7d179845d72c4df6b1bfa01018d43af9d36cdcbf393066f9465f5197c7")
            ),
        ]

        // when
        let hashes = try builder.buildForSign(transaction: transaction)
        let encoded = try builder.buildForSend(transaction: transaction, signatures: signatures)

        // then
        #expect(defaultAddress.value == "bc1qx427ycxzg7cak7zxelv25lts9n2tvhcgjff54z")
        #expect(legacyAddress.value == "15s1hWhSVQLxPQArF5DEd42QgqrzzPjo9G")
        #expect(hashes == signatures.map(\.hash))
        #expect(encoded == Data(hexString: "01000000000102139b77b32fd54523c68485511fa9cd88601b6965c229e94bc1977dd0e11284ea0000000000ffffffff8e1feb0836f94e41723d57bfb7232b138a3f9c34dcaecfd17265f7bab56562c5000000006b4830450221009dae8b07d96dd4bd908e567f1f7595fe476ffd6c0d273f604060dc858ba8bebc02206fdf3edeb02f1be490b9011923d75f85c9f19df813a3096c3b0bda0c3ffd45bb01210256e4711ea6bf3309e039ee30b203b18783a8c7c78c68ff2e36acec3c6f51c884ffffffff01c2060000000000002200205c39ca891044173cee9705f99dd7cff3bcb8380aa705bf9f494a254f196bc478024730440220611255ea986b38e90769dad8176b0850b55ab8c0e4ae01bc857eef7253c0c76902204a15a870f80be4fcb55af33f38fe2129058ac7025436bdfcee299f7c51db5ba301210256e4711ea6bf3309e039ee30b203b18783a8c7c78c68ff2e36acec3c6f51c8840000000000"))
    }
}
