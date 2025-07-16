//
//  LitecoinTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

final class LitecoinTransactionTests {
    /// https://blockchair.com/litecoin/transaction/e137c6b47d2553104897a2bb769c638a019c838f84d69d729b879f7568ab0fd5
    @Test(arguments: [BitcoinTransactionBuilder.BuilderType.walletCore(.litecoin), .custom])
    func legacyAndDefaultAddressTransaction(builderType: BitcoinTransactionBuilder.BuilderType) async throws {
        // given
        let networkParams = LitecoinNetworkParams()
        let pubKey = Data(hexString: "0252b019a84e128ea96413179ee5185a07d5eeb7b4755a29416c1b9b8d92fae3aa")
        let addressService = BitcoinAddressService(networkParams: networkParams)
        let defaultAddress = try addressService.makeAddress(from: pubKey, type: .default)
        let legacyAddress = try addressService.makeAddress(from: pubKey, type: .legacy)

        let unspentOutputManager: UnspentOutputManager = .litecoin(address: defaultAddress)
        unspentOutputManager.update(
            outputs: [.init(blockId: 2876580, txId: "b530464567f64eea2566fcda6d5953f567474c05cae13dd3dbba9dcf8d990310", index: 3, amount: 5000000)],
            for: defaultAddress
        )

        unspentOutputManager.update(
            outputs: [.init(blockId: 2876582, txId: "f22e5c969d41f967d983974c27b1c1c63021a041d0529a5c2d88caa3659ed2f6", index: 3, amount: 8909297)],
            for: legacyAddress
        )

        let builder = BitcoinTransactionBuilder(network: networkParams, unspentOutputManager: unspentOutputManager, builderType: builderType, sequence: .final)
        let transaction = Transaction(
            amount: Amount(with: .litecoin, value: .init(stringValue: "0.1")!),
            fee: Fee(.init(with: .litecoin, value: .init(stringValue: "0.00000289")!), parameters: BitcoinFeeParameters(rate: 1)),
            sourceAddress: defaultAddress.value,
            destinationAddress: "ltc1qcadgn7d9ytzusq2lxzx8fdf8tqqd9sppggya8t",
            changeAddress: defaultAddress.value
        )

        let signatures = [
            SignatureInfo(
                signature: Data(hexString: "dd70ea19dba2dae8e975d96d9451f3b1902e3cd84dd5729ade62ff29b16112af1148330585572d6b2e44ea4b9b2c694d6c9153d6ab1552f9f19092f13ac1fa59"),
                publicKey: pubKey,
                hash: Data(hexString: "32a83e7331df0f42203d1d29db0f7ae912a34a57ed5694f9b6f5ae5ad40b73cc")
            ),
            SignatureInfo(
                signature: Data(hexString: "5e280d8344f5b7ea98bf95349cdb9a5eaed409ea746ab91084db5b0894012b3875d68fc21717f266b9369ff3c81f3a84d13c1c368aedb5c08d1f26516ff37d70"),
                publicKey: pubKey,
                hash: Data(hexString: "f1382347457c9627ac9f01e03ae3bfbcdc418535ed8a5a704624128f43ccdc76")
            ),
        ]

        // when
        let hashes = try await builder.buildForSign(transaction: transaction)
        let encoded = try await builder.buildForSend(transaction: transaction, signatures: signatures)

        // then
        #expect(defaultAddress.value == "ltc1qxj6zrp9ea8kvlcq58qzw09a74rxlsecgu29nu0")
        #expect(legacyAddress.value == "LQ2dBuRmPSgNJXBd9Vgqn2chzeGoeQMAnA")
        #expect(hashes == signatures.map(\.hash))
        #expect(encoded == Data(hexString: "010000000001021003998dcf9dbadbd33de1ca054c4767f553596ddafc6625ea4ef667454630b50300000000fffffffff6d29e65a3ca882d5c9a52d041a02130c6c1b1274c9783d967f9419d965c2ef2030000006a47304402205e280d8344f5b7ea98bf95349cdb9a5eaed409ea746ab91084db5b0894012b38022075d68fc21717f266b9369ff3c81f3a84d13c1c368aedb5c08d1f26516ff37d7001210252b019a84e128ea96413179ee5185a07d5eeb7b4755a29416c1b9b8d92fae3aaffffffff028096980000000000160014c75a89f9a522c5c8015f308c74b5275800d2c02190a53b000000000016001434b42184b9e9eccfe0143804e797bea8cdf8670802483045022100dd70ea19dba2dae8e975d96d9451f3b1902e3cd84dd5729ade62ff29b16112af02201148330585572d6b2e44ea4b9b2c694d6c9153d6ab1552f9f19092f13ac1fa5901210252b019a84e128ea96413179ee5185a07d5eeb7b4755a29416c1b9b8d92fae3aa0000000000"))
    }
}
