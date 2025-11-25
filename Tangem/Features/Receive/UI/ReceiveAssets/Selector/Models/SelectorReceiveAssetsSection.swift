//
//  SelectorReceiveAssetsSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct SelectorReceiveAssetsSection: Identifiable {
    let id: Key
    let items: [SelectorReceiveAssetsContentItemViewModel]
}

// MARK: - Key

extension SelectorReceiveAssetsSection {
    enum Key: String, Identifiable, Hashable, CaseIterable {
        var id: String {
            rawValue
        }

        case domain
        case `default`
    }
}
