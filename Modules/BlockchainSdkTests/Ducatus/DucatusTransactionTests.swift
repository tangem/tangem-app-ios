//
//  DucatusTransactionTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
import TangemFoundation
@testable import BlockchainSdk

struct DucatusTransactionTests {
    /// https://insight.ducatus.io/#/DUC/mainnet/tx/bc7278a59187504a1b50d93b84315f6270c2db9dfd882937cde62f362db20e78
    @Test(.serialized, arguments: [BitcoinTransactionBuilder.BuilderType.custom])
    func transaction(builderType: BitcoinTransactionBuilder.BuilderType) async throws {
        // given
        let pubKey = Data(hexString: "02b4a38ad5f363f91b9285a8c28040d87eb70bb63fee172f62aad261021d44e051")
        let addressService = AddressServiceFactory(blockchain: .ducatus).makeAddressService()
        let address = try addressService.makeAddress(from: pubKey, type: .default)
        let unspentOutputManager: UnspentOutputManager = .ducatus(address: address)

        unspentOutputManager.update(
            outputs: [
                .init(blockId: 2811998, txId: "bc7278a59187504a1b50d93b84315f6270c2db9dfd882937cde62f362db20e78", index: 0, amount: 863968),
            ],
            for: address
        )

        let builder = BitcoinTransactionBuilder(
            network: DucatusNetworkParams(), unspentOutputManager: unspentOutputManager, builderType: builderType, sequence: .rbf
        )

        let transaction = Transaction(
            amount: Amount(with: .ducatus, value: Decimal(stringValue: "0.0083632")!),
            fee: Fee(.init(with: .ducatus, value: Decimal(stringValue: "0.00027648")!), parameters: BitcoinFeeParameters(rate: 144)),
            sourceAddress: address.value,
            destinationAddress: "M3o4mfN17fBu58CNDHFVnZXvuJrKVo84A7",
            changeAddress: address.value
        )

        let signatures = [
            SignatureInfo(
                signature: Data(hexString: "880e13c9d4efe8e75ada2cc86bacf5d6d40f6e9baff471ba9ecbf7a56cf1555a3c5ca4d05f2d9cb16c996bf1d6ce973556ec964c06e4f495ce7e2338b5a075a3"),
                publicKey: pubKey,
                hash: Data(hexString: "8c9f92d8120d0997e736b5821949c41c9c7ac54d8976ece7911cc4eee7df490a")
            ),
        ]

        // when
        let hashes = try await builder.buildForSign(transaction: transaction)
        let encoded = try await builder.buildForSend(transaction: transaction, signatures: signatures)

        // then
        #expect(address.value == "LjENuNAaDSVjJeRBJKi4doAC8Zpwuz1E3V")
        #expect(hashes == signatures.map(\.hash))
        #expect(encoded == Data(hexString: "0100000001780eb22d362fe6cd372988fd9ddbc270625f31843bd9501b4a508791a57872bc000000006b483045022100880e13c9d4efe8e75ada2cc86bacf5d6d40f6e9baff471ba9ecbf7a56cf1555a02203c5ca4d05f2d9cb16c996bf1d6ce973556ec964c06e4f495ce7e2338b5a075a3012102b4a38ad5f363f91b9285a8c28040d87eb70bb63fee172f62aad261021d44e051fdffffff01e0c20c00000000001976a914d2f8712a2ccc5903e7862a1eb57416ee6bc3fb7088ac00000000"))
    }
}
