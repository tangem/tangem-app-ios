//
//  EarnEthereumP2PFilter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol EarnEthereumP2PFilter {
    func filter(_ items: [EarnDTO.List.Item]) async throws -> [EarnDTO.List.Item]
}
