//
//  ApplicationWalletEntry.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ApplicationWalletEntry: Hashable, Identifiable {
    let id: String
    let name: String
    let notifyStatus: Bool
}
