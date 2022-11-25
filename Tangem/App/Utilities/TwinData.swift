//
//  TwinData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

enum TwinCardSeries: String, Codable, CaseIterable {
    case cb61 = "CB61"
    case cb62 = "CB62"
    case cb64 = "CB64"
    case cb65 = "CB65"

    var number: Int {
        switch self {
        case .cb61, .cb64: return 1
        case .cb62, .cb65: return 2
        }
    }

    var pair: TwinCardSeries {
        switch self {
        case .cb61: return .cb62
        case .cb62: return .cb61
        case .cb64: return .cb65
        case .cb65: return .cb64
        }
    }

    static func series(for cardId: String) -> TwinCardSeries? {
        TwinCardSeries.allCases.first(where: { cardId.hasPrefix($0.rawValue) })
    }
}

struct TwinData: Codable {
    let series: TwinCardSeries
    var pairPublicKey: Data?
}
