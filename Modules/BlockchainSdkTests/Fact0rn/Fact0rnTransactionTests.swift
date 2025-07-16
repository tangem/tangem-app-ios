//
//  Fact0rnTransactionTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

struct Fact0rnTransactionTests {
    @Test(arguments: [BitcoinTransactionBuilder.BuilderType.custom])
    func transaction(builderType: BitcoinTransactionBuilder.BuilderType) async throws {
        // given
        let pubKey = Data(hexString: "03f605d4a94e07ae7ddc1dafea08ade5f6db0fb9f0d40c0409007b1e47e4ac3bed")
        let addressService = AddressServiceFactory(blockchain: .fact0rn).makeAddressService()
        let address = try addressService.makeAddress(from: pubKey, type: .default)
        let unspentOutputManager: UnspentOutputManager = .fact0rn(address: address)

        unspentOutputManager.update(
            outputs: [
                .init(blockId: 166635, txId: "799197108ad314857193705732a881c22f01abf869c2d6cc7afcf046dd1c9433", index: 0, amount: 94871),
            ],
            for: address
        )

        let builder = BitcoinTransactionBuilder(
            network: Fact0rnMainNetworkParams(), unspentOutputManager: unspentOutputManager, builderType: builderType, sequence: .rbf
        )

        let transaction = Transaction(
            amount: Amount(with: .fact0rn, value: Decimal(stringValue: "0.00094759")!),
            fee: Fee(.init(with: .fact0rn, value: Decimal(stringValue: "0.00000112")!)),
            sourceAddress: address.value,
            destinationAddress: "fact1qltjlrsty49500xyh9dea470gfs7zx5rhk62tsa",
            changeAddress: address.value
        )

        let signatures = [
            SignatureInfo(
                signature: Data(hexString: "2f5c626793589c02acdb08a89a209278b38876aa508ef94c08b38d95ea9ddcf20319d472856158981b364f01f0e292df1121baa8788a7faec416714bfd565695"),
                publicKey: pubKey,
                hash: Data(hexString: "2d7ca30c57941551c6b1146b168e1972f878ed63e70f55575c7c581d20dc8fc6")
            ),
        ]

        // when
        let hashes = try await builder.buildForSign(transaction: transaction)
        let encoded = try await builder.buildForSend(transaction: transaction, signatures: signatures)

        // then
        #expect(address.value == "fact1qn7085dmevapmgkf5ztj4t3jz6rwwcjttt0rpt2")
        #expect(hashes == signatures.map(\.hash))
        #expect(encoded == Data(hexString: "0100000000010133941cdd46f0fc7accd6c269f8ab012fc281a832577093718514d38a109791790000000000fdffffff012772010000000000160014fae5f1c164a968f798972b73daf9e84c3c2350770247304402202f5c626793589c02acdb08a89a209278b38876aa508ef94c08b38d95ea9ddcf202200319d472856158981b364f01f0e292df1121baa8788a7faec416714bfd565695012103f605d4a94e07ae7ddc1dafea08ade5f6db0fb9f0d40c0409007b1e47e4ac3bed00000000"))
    }
}
