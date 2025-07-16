//
//  CloreTransactionTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
import enum WalletCore.CoinType
@testable import BlockchainSdk

struct CloreTransactionTests {
    /// https://clore.cryptoscope.io/tx/?txid=98edcf88c6b6d480635dc33adf948c00e81bcea35fbec548edbc3a2e11f0a978
    @Test(arguments: [BitcoinTransactionBuilder.BuilderType.custom])
    func transaction(builderType: BitcoinTransactionBuilder.BuilderType) async throws {
        // given
        let pubKey = Data(hexString: "03a08920b8940d992d58f2ac6f285a97f126634d709e31e28fb5892614e6494e5c")
        let addressService = BitcoinLegacyAddressService(networkParams: CloreMainNetworkParams())
        let address = try addressService.makeAddress(from: pubKey, type: .default)
        let unspentOutputManager: UnspentOutputManager = .clore(address: address)

        unspentOutputManager.update(
            outputs: [
                .init(blockId: 1307306, txId: "e6f778989324b40d52a60e4cde74aaf09da659d5f651a07724814bc236b0c015", index: 1, amount: 99647214),
            ],
            for: address
        )

        let builder = BitcoinTransactionBuilder(
            network: CloreMainNetworkParams(), unspentOutputManager: unspentOutputManager, builderType: builderType, sequence: .rbf
        )

        let transaction = Transaction(
            amount: Amount(with: .clore, value: Decimal(stringValue: "0.99347502")!),
            fee: Fee(.init(with: .clore, value: Decimal(stringValue: "0.00299712")!), parameters: BitcoinFeeParameters(rate: 1561)),
            sourceAddress: address.value,
            destinationAddress: "AVE1y9coirTppkjX2By7wjZv7Qd1vKvmNw",
            changeAddress: address.value
        )

        let signatures = [
            SignatureInfo(
                signature: Data(hexString: "6dba2937a8f947fd8933f8a0495d48b7c04b875c2d96cb916114226911554f326eded623f6eba821de9f8ae7905f4081cc7cd9861aa1e50e638a338eb76c086d"),
                publicKey: pubKey,
                hash: Data(hexString: "5e9f8f78c72cc629847b4a304e146812b384fdbeddf5bb65e1ecdf66a645e58c")
            ),
        ]

        // when
        let hashes = try await builder.buildForSign(transaction: transaction)
        let encoded = try await builder.buildForSend(transaction: transaction, signatures: signatures)

        // then
        #expect(address.value == "AVWee1FwY3nJTcANjbj9QktHirkzUrGefm")
        #expect(hashes == signatures.map(\.hash))
        #expect(encoded == Data(hexString: "010000000115c0b036c24b812477a051f6d559a69df0aa74de4c0ea6520db424939878f7e6010000006a47304402206dba2937a8f947fd8933f8a0495d48b7c04b875c2d96cb916114226911554f3202206eded623f6eba821de9f8ae7905f4081cc7cd9861aa1e50e638a338eb76c086d012103a08920b8940d992d58f2ac6f285a97f126634d709e31e28fb5892614e6494e5cfdffffff012eeceb05000000001976a914938b658da3c1bbabf91f3a3d8fec26e489396f2588ac00000000"))
    }
}
