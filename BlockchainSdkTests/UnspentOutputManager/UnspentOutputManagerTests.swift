//
//  UnspentOutputManagerTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

class UnspentOutputManagerTests {
    /// https://www.blockchain.com/explorer/transactions/btc/3841e727416897dbce40ddf2e5eec1cfb255058c1ad1ce5cb7cee0ca2140706b
    @Test
    func spendingSomeAmount() async throws {
        // given
        let addressService = AddressServiceFactory(blockchain: .bitcoin(testnet: false)).makeAddressService()
        let address = try addressService.makeAddress(from: Keys.Secp256k1.publicKey)

        let outputs = [
            UnspentOutput(blockId: 1, txId: "f1d306a65784348f831a38caf028323aab4ea01d40c80d31f4b5fa2eca8969bb", index: 0, amount: 3000),
            UnspentOutput(blockId: 2, txId: "5509df5c6e2631dcb093d5bc09065b156039f400a7b1642caa5c7ec88a260b61", index: 0, amount: 1000),
        ]

        let manager: UnspentOutputManager = .bitcoin(address: address, isTestnet: false)
        manager.update(outputs: outputs, for: address)

        // when
        let preImage = try await manager.preImage(amount: 2000, feeRate: 3, destination: "bc1qu4tzv3wfylvqx5rvsjj9nlxlralncqtwvwn0jh")
        let preImageExactlyFee = try await manager.preImage(amount: 2000, fee: 429, destination: "bc1qu4tzv3wfylvqx5rvsjj9nlxlralncqtwvwn0jh")

        // then
        #expect(preImage.inputs.count == 1, "Selected only one input")
        #expect(preImage.inputs.first?.amount == 3000)
        #expect(preImage.inputs.first?.txId == "f1d306a65784348f831a38caf028323aab4ea01d40c80d31f4b5fa2eca8969bb")

        #expect(preImage.outputs.count == 2)
        #expect(preImage.fee == 429)

        preImage.outputs.forEach { output in
            switch output {
            case .change(let script, let value):
                #expect(script.type == .p2wpkh)
                #expect(value == 571)
            case .destination(let script, let value):
                #expect(script.type == .p2wpkh)
                #expect(value == 2000)
            }
        }

        #expect(preImage == preImageExactlyFee)
    }

    /// https://www.blockchain.com/explorer/transactions/btc/7bf63b83a858838ceab579bf9334866af72722f68be5a04a82d9b478f5ea6246
    @Test
    func spendingFullAmountFeeCalculation() async throws {
        // given
        let addressService = AddressServiceFactory(blockchain: .bitcoin(testnet: false)).makeAddressService()
        let address = try addressService.makeAddress(from: Keys.Secp256k1.publicKey)

        let outputs = [
            UnspentOutput(blockId: 1, txId: "3841e727416897dbce40ddf2e5eec1cfb255058c1ad1ce5cb7cee0ca2140706b", index: 0, amount: 577),
            UnspentOutput(blockId: 2, txId: "5509df5c6e2631dcb093d5bc09065b156039f400a7b1642caa5c7ec88a260b61", index: 0, amount: 1000),
        ]

        let manager: UnspentOutputManager = .bitcoin(address: address, isTestnet: false)
        manager.update(outputs: outputs, for: address)

        // when
        let preImage = try await manager.preImage(amount: 1577, feeRate: 2, destination: "bc1qu4tzv3wfylvqx5rvsjj9nlxlralncqtwvwn0jh")

        // then
        #expect(preImage.inputs.count == 2)
        #expect(preImage.outputs.count == 1)
        #expect(preImage.outputs.contains(where: { $0.isDestination }))
        #expect(preImage.outputs.first?.value == 1577)
        #expect(preImage.fee == 360)
    }

    /// https://www.blockchain.com/explorer/transactions/btc/7bf63b83a858838ceab579bf9334866af72722f68be5a04a82d9b478f5ea6246
    @Test
    func spendingFullAmountWithReducedAmountOnFee() async throws {
        // given
        let addressService = AddressServiceFactory(blockchain: .bitcoin(testnet: false)).makeAddressService()
        let address = try addressService.makeAddress(from: Keys.Secp256k1.publicKey)

        let outputs = [
            UnspentOutput(blockId: 1, txId: "3841e727416897dbce40ddf2e5eec1cfb255058c1ad1ce5cb7cee0ca2140706b", index: 0, amount: 577),
            UnspentOutput(blockId: 2, txId: "5509df5c6e2631dcb093d5bc09065b156039f400a7b1642caa5c7ec88a260b61", index: 0, amount: 1000),
        ]

        let manager: UnspentOutputManager = .bitcoin(address: address, isTestnet: false)
        manager.update(outputs: outputs, for: address)

        // when
        let preImage = try await manager.preImage(amount: 1221, fee: 356, destination: "bc1qu4tzv3wfylvqx5rvsjj9nlxlralncqtwvwn0jh")

        // then
        #expect(preImage.inputs.count == 2)
        #expect(preImage.outputs.count == 1)
        #expect(preImage.outputs.contains(where: { $0.isDestination }))
        #expect(preImage.outputs.first?.value == 1221)
        #expect(preImage.fee == 356)
    }
}
