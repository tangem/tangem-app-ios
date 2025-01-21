//
//  AlephiumNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
final class AlephiumNetworkService: MultiNetworkProvider {
    var providers: [AlephiumNetworkProvider] = []
    var currentProviderIndex: Int = 0
}
