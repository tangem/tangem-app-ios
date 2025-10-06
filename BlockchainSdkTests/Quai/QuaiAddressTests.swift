//
//  QuaiAddressTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing

struct QuaiAddressTests {
    private let blockchain = Blockchain.quai(testnet: false)
    private let derivationUtils = QuaiDerivationUtils()
    private let protoUtils = QuaiProtobufUtils()

    @Test(arguments: [Constants.defaultExtendendPublicKey])
    func defaultAddressGeneration(extendedPublicKey: ExtendedPublicKey) throws {
        // given
        let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        // when
        let zoneDerivedResult = try derivationUtils.derive(extendedPublicKey: extendedPublicKey, with: .default)
        let walletPublicKey = Wallet.PublicKey(seedKey: zoneDerivedResult.0.publicKey, derivationType: .none)
        let zoneDerivedAddress = try service.makeAddress(for: walletPublicKey, with: .default)

        // then
        #expect(zoneDerivedAddress.value == "0x004842973c76D783037E41eb3917DAc7777dA099")
    }
}

extension QuaiAddressTests {
    enum Constants {
        static let defaultExtendendPublicKey: ExtendedPublicKey = try! .init(
            from: "xpub661MyMwAqRbcG9Vf9WYGEatsHhHv3QNs1nDXjuLC9WLfgeHNcXRnbwAefZ1U8qph9neMN6RjX75QK6NEzmGPoWeeuvw2xr1vfZpnJ62Vzji", networkType: .mainnet
        )
    }
}
