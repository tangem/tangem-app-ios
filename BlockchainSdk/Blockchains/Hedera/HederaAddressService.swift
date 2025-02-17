//
//  HederaAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Hedera

final class HederaAddressService: AddressService {
    private let isTestnet: Bool

    private lazy var client: Client = isTestnet ? Client.forTestnet() : Client.forMainnet()

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        BSDKLogger.warning(
            """
            Address for the Hedera blockchain (Testnet: \(isTestnet)) is requested but can't be provided. \
            Obtain actual address using `Wallet.address`
            """
        )
        return PlainAddress(value: "", publicKey: publicKey, type: addressType)
    }

    func validate(_ address: String) -> Bool {
        do {
            try AccountId
                .fromString(address)
                .validateChecksum(client)
            return true
        } catch {
            return false
        }
    }
}
