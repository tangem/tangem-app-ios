//
//  HotWalletId.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct HotWalletID: Equatable, Hashable, Codable {
    public let value: String

    init() {
        value = UUID().uuidString
    }
}
