//
//  NFTNetworkSelectionListItemViewData.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemUI.TokenIconInfo

struct NFTNetworkSelectionListItemViewData: Identifiable {
    let id = UUID()
    let title: String
    let tokenIconInfo: TokenIconInfo
    let isAvailable: Bool
    let tapAction: () -> Void
}

// MARK: - Equatable protocol conformance

extension NFTNetworkSelectionListItemViewData: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.tokenIconInfo == rhs.tokenIconInfo
            && lhs.isAvailable == rhs.isAvailable
    }
}

// MARK: - Hashable protocol conformance

extension NFTNetworkSelectionListItemViewData: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(tokenIconInfo)
        hasher.combine(isAvailable)
    }
}
