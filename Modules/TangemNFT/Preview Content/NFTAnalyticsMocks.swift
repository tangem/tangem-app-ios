//
//  NFTAnalyticsMocks.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension NFTAnalytics.Collections {
    static var empty: Self {
        .init(logReceiveOpen: {}, logDetailsOpen: { _, _ in })
    }
}

public extension NFTAnalytics.BlockchainSelection {
    static var empty: Self {
        .init(
            logBlockchainChosen: { _ in },
        )
    }
}

extension NFTAnalytics.Details {
    static var empty: Self {
        .init(
            logReadMoreTapped: {},
            logSeeAllTapped: {},
            logExploreTapped: {},
            logSendTapped: {}
        )
    }
}

extension NFTAnalytics.Error {
    static var empty: Self {
        .init(logError: { _, _ in })
    }
}

extension NFTAnalytics.Entrypoint {
    static var empty: Self {
        .init(logCollectionsOpen: { _, _, _, _ in })
    }
}
