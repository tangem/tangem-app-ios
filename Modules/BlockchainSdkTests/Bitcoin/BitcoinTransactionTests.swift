//
//  BitcoinTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
import TangemFoundation
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
    @Test(.serialized, arguments: [BitcoinTransactionBuilder.BuilderType.walletCore(.bitcoin), .custom])
    func legacyAndDefaultAddressTransaction(builderType: BitcoinTransactionBuilder.BuilderType) async throws {
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

        let builder = BitcoinTransactionBuilder(network: networkParams, unspentOutputManager: unspentOutputManager, builderType: builderType, sequence: .final)
        let transaction = Transaction(
            amount: Amount(with: .bitcoin(testnet: false), value: .init(stringValue: "0.00001730")!),
            fee: Fee(.init(with: .bitcoin(testnet: false), value: .init(stringValue: "0.00000270")!), parameters: BitcoinFeeParameters(rate: 1)),
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
        let hashes = try await builder.buildForSign(transaction: transaction)
        let encoded = try await builder.buildForSend(transaction: transaction, signatures: signatures)

        // then
        #expect(defaultAddress.value == "bc1qx427ycxzg7cak7zxelv25lts9n2tvhcgjff54z")
        #expect(legacyAddress.value == "15s1hWhSVQLxPQArF5DEd42QgqrzzPjo9G")
        #expect(hashes == signatures.map(\.hash))
        #expect(encoded == Data(hexString: "01000000000102139b77b32fd54523c68485511fa9cd88601b6965c229e94bc1977dd0e11284ea0000000000ffffffff8e1feb0836f94e41723d57bfb7232b138a3f9c34dcaecfd17265f7bab56562c5000000006b4830450221009dae8b07d96dd4bd908e567f1f7595fe476ffd6c0d273f604060dc858ba8bebc02206fdf3edeb02f1be490b9011923d75f85c9f19df813a3096c3b0bda0c3ffd45bb01210256e4711ea6bf3309e039ee30b203b18783a8c7c78c68ff2e36acec3c6f51c884ffffffff01c2060000000000002200205c39ca891044173cee9705f99dd7cff3bcb8380aa705bf9f494a254f196bc478024730440220611255ea986b38e90769dad8176b0850b55ab8c0e4ae01bc857eef7253c0c76902204a15a870f80be4fcb55af33f38fe2129058ac7025436bdfcee299f7c51db5ba301210256e4711ea6bf3309e039ee30b203b18783a8c7c78c68ff2e36acec3c6f51c8840000000000"))
    }

    /// https://www.blockchair.com/bitcoin/transaction/b197d829e5eba01cab1800a813c9c94629c97fbfac4307f3f0fb51b1fbe2e5f3
    /// Twin cards
    @Test(.serialized, arguments: [BitcoinTransactionBuilder.BuilderType.walletCore(.bitcoin), .custom])
    func p2msTransaction(builderType: BitcoinTransactionBuilder.BuilderType) async throws {
        // given
        let networkParams = BitcoinNetworkParams()
        let pubKey = Data(hexString: "0498bf2d8ebc710c1dece61ed077c10a08cc915a8757b42ace86c05443a96fe3f30488e234c426d01e1c10296e0dd9db3176a24e78bc30375428f5f363d79942aa")
        let pairPubKey = Data(hexString: "0463d452ff8a11ccaec8f567b6af7b0200fb764906f1fdada40545e8a9cd500d3900f17e544a4e97cf8d197a992e4e1febc388ef7393e9f865d6c260404c5a8247")
        let addressService = BitcoinAddressService(networkParams: networkParams)
        let addresses = try addressService.makeAddresses(publicKey: .init(seedKey: pubKey, derivationType: .none), pairPublicKey: pairPubKey)
        let defaultAddress = try #require(addresses.first(where: { $0.type == .default }))
        let legacyAddress = try #require(addresses.first(where: { $0.type == .legacy }))

        let unspentOutputManager: UnspentOutputManager = .bitcoin(address: defaultAddress, isTestnet: false)
        unspentOutputManager.update(
            outputs: [.init(blockId: 891765, txId: "1df3c8aa649e1c1b3760685a0fc1ac7b3dd9be7e0ab35f7accf8195737e6caac", index: 0, amount: 1730)],
            for: defaultAddress
        )

        let builder = BitcoinTransactionBuilder(network: networkParams, unspentOutputManager: unspentOutputManager, builderType: builderType, sequence: .final)
        let transaction = Transaction(
            amount: Amount(with: .bitcoin(testnet: false), value: .init(stringValue: "0.0000161")!),
            fee: Fee(.init(with: .bitcoin(testnet: false), value: .init(stringValue: "0.0000012")!), parameters: BitcoinFeeParameters(rate: 1)),
            sourceAddress: defaultAddress.value,
            destinationAddress: "bc1qu4tzv3wfylvqx5rvsjj9nlxlralncqtwvwn0jh",
            changeAddress: defaultAddress.value
        )

        let signatures = [
            SignatureInfo(
                signature: Data(hexString: "ba35d9769e08c42ba1935229465dd28758e039b82ec0c4261cab919fd811057b545ea34827d2248d7924305983858f78c3f1723b5ded2a853d2c80cf506d6cd2"),
                publicKey: pubKey,
                hash: Data(hexString: "40ba1ace675093a175509af1848f8166d9ff3ea79197cb26e029c3bb1f15144e")
            ),
        ]

        // when
        let hashes = try await builder.buildForSign(transaction: transaction)
        let encoded = try await builder.buildForSend(transaction: transaction, signatures: signatures)

        // then
        #expect(defaultAddress.value == "bc1qtsuu4zgsgstnem5hqhuem4707w7tswq25uzml86ffgj57xttc3uqptg999")
        #expect(legacyAddress.value == "3Fcg63kfem9XyTf5J5sDyksf93LW38i9ni")
        #expect(hashes == signatures.map(\.hash))
        #expect(encoded == Data(hexString: "01000000000101accae6375719f8cc7a5fb30a7ebed93d7bacc10f5a6860371b1c9e64aac8f31d0000000000ffffffff014a06000000000000160014e5562645c927d803506c84a459fcdf1f7f3c016e0300483045022100ba35d9769e08c42ba1935229465dd28758e039b82ec0c4261cab919fd811057b0220545ea34827d2248d7924305983858f78c3f1723b5ded2a853d2c80cf506d6cd2014751210298bf2d8ebc710c1dece61ed077c10a08cc915a8757b42ace86c05443a96fe3f3210363d452ff8a11ccaec8f567b6af7b0200fb764906f1fdada40545e8a9cd500d3952ae00000000"))
    }
}
