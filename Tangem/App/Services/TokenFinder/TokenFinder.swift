//
//  TokenFinder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdkLocal

protocol TokenFinder {
    func findToken(contractAddress: String, networkId: String) async throws -> TokenItem
}
