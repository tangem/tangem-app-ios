//
//  RavencoinTransactionTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

struct RavencoinTransactionTests {
    /// https://blockbook.ravencoin.org/tx/c6103bc13fb76814f1a2d34a0e61ca51666bc750db8bba03c04ffc188739dce7
    @Test(arguments: [BitcoinTransactionBuilder.BuilderType.walletCore(.ravencoin), .custom])
    func transaction(builderType: BitcoinTransactionBuilder.BuilderType) async throws {
        // given
        let pubKey = Data(hexString: "02677dd71d01665229de974005670618568b83f6b1e0809aabb99b1646bdc660bb")
        let addressService = AddressServiceFactory(blockchain: .ravencoin(testnet: false)).makeAddressService()
        let address = try addressService.makeAddress(from: pubKey)
        let unspentOutputManager: UnspentOutputManager = .ravencoin(address: address, isTestnet: false)
        unspentOutputManager.update(outputs: [
            .init(blockId: 3793801, txId: "f303c9828af090314f6ab2dc953c21d93e18aaa7c6f3db6e99437d7658412a59", index: 1, amount: 186367788),
        ], for: address)
        let builder = BitcoinTransactionBuilder(network: RavencoinMainNetworkParams(), unspentOutputManager: unspentOutputManager, builderType: builderType, sequence: .final)
        let transaction = Transaction(
            amount: Amount(with: .ravencoin(testnet: false), value: 0.05),
            fee: Fee(.init(with: .ravencoin(testnet: false), value: 0.00275268), parameters: BitcoinFeeParameters(rate: 1218)),
            sourceAddress: address.value,
            destinationAddress: "R9evUf3dCSfzdjuRJgvBxAnjA7TPjDYjPo",
            changeAddress: address.value
        )
        let signatures = [
            SignatureInfo(
                signature: Data(hexString: "b9ef66034d8da7cf4be4aa86ac3a8d1a6a941767f9add309a03e15f70a1c9a12628100fd65c9209a353e3eff108bb2763c129cb7c1254e5b9c546fa942e218a1"),
                publicKey: pubKey,
                hash: Data(hexString: "6f19e210333abfc47ba3d8ae04fe2a67cc3e2a9a92178d03a4a92fa5cb2fa6e1")
            ),
        ]

        // when
        let hashes = try await builder.buildForSign(transaction: transaction)
        let encoded = try await builder.buildForSend(transaction: transaction, signatures: signatures)

        // then
        #expect(address.value == "RLAppkUmJsgdQ7Khb7ZfL8JG14kaWzjFhK")
        #expect(hashes == signatures.map(\.hash))
        #expect(encoded == Data(hexString: "0100000001592a4158767d43996edbf3c6a7aa183ed9213c95dcb26a4f3190f08a82c903f3010000006b483045022100b9ef66034d8da7cf4be4aa86ac3a8d1a6a941767f9add309a03e15f70a1c9a120220628100fd65c9209a353e3eff108bb2763c129cb7c1254e5b9c546fa942e218a1012102677dd71d01665229de974005670618568b83f6b1e0809aabb99b1646bdc660bbffffffff02404b4c00000000001976a914041c20c9f7d7e16cb2813da977bc9901a8e7d0d688aca840cb0a000000001976a9147775253a54f9873fe3065877a423e4191057d8b988ac00000000"))
    }
}
