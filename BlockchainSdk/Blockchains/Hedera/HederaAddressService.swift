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
            let accountId = try AccountId.fromSolidityAddressOrString(address)
            try accountId.validateChecksum(client)
            // For now, we’ve decided to accept as valid only shard 0 / realm 0 addresses.
            // Also ensure `num` fits into Int64; otherwise `AccountId.toProtobuf()` crashes on overflow.
            guard accountId.shard == 0,
                  accountId.realm == 0,
                  Int64(exactly: accountId.num) != nil
            else {
                return false
            }
            return true
        } catch {
            return false
        }
    }
}
