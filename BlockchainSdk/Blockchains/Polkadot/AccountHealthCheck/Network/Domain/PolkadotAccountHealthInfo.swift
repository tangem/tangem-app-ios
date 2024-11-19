//
//  PolkadotAccountHealthInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum PolkadotAccountHealthInfo {
    case nonExistentAccount
    case existingAccount(extrinsicCount: Int, nonceCount: Int)
}
