//
//  YieldModuleUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum YieldModuleUtils {
    static func parseEthereumAddress(_ string: String) -> String? {
        let noHexPrefixString = string.removeHexPrefix()
        let ethereumAddressLength = 40

        guard noHexPrefixString.count >= ethereumAddressLength else {
            return nil
        }

        let addressPart = String(noHexPrefixString.suffix(ethereumAddressLength))

        guard !addressPart.allSatisfy({ $0 == "0" }) else {
            return nil
        }

        return addressPart.addHexPrefix()
    }
}
