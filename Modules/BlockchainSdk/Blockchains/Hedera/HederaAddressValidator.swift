//
//  HederaAddressValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Hiero
import TangemFoundation

final class HederaAddressValidator {
    private let isTestnet: Bool
    private let client: Client

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        client = isTestnet ? Client.forTestnetWithImmediateUpdate(plaintextOnly: true) : Client.forMainnetWithImmediateUpdate(plaintextOnly: true)
    }

    func isValid(address: String) -> Bool {
        do {
            let accountId = try AccountId.fromSolidityAddressOrString(address)
            try accountId.validateChecksum(client)
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
