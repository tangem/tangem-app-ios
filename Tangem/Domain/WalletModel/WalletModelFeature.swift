//
//  WalletModelFeature.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT

// MARK: - Identifiable

enum WalletModelFeatureId: String, Identifiable {
    case nft
    case staking
    case transactionHistory
    case send

    var id: String { rawValue }
}

enum WalletModelFeature {
    case nft(networkService: NFTNetworkService)

    @available(*, unavailable, message: "This feature is not implemented yet")
    case staking

    @available(*, unavailable, message: "This feature is not implemented yet")
    case transactionHistory

    case send(logger: NetworkProviderAnalyticsLogger)
}

extension WalletModelFeature: Identifiable {
    var id: WalletModelFeatureId {
        switch self {
        case .nft: return .nft
        case .staking: return .staking
        case .transactionHistory: return .transactionHistory
        case .send: return .send
        }
    }
}

// MARK: -

extension Array where Element == WalletModelFeature {
    func find(id: WalletModelFeatureId) -> WalletModelFeature? {
        return first(where: { $0.id == id })
    }
}
