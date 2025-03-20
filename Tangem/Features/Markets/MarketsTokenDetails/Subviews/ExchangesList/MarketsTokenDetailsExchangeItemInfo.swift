//
//  MarketsTokenDetailsExchangeItemInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsTokenDetailsExchangeItemInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let trustScore: MarketsExchangeTrustScore
    let exchangeType: ExchangeType
    let iconURL: URL?
    let formattedVolume: String
}

extension MarketsTokenDetailsExchangeItemInfo {
    enum ExchangeType: String {
        case cex
        case dex

        var title: String {
            rawValue.uppercased()
        }
    }
}
