//
//  MarketCapInfoBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization

final class MarketCapInfoBottomSheetViewModel {
    let subject: MarketCapInfoSubject
    let closeAction: () -> Void

    var title: String {
        switch subject {
        case .totalMarketCap: Localization.marketCryptoTotalMarketCapTitle
        case .index(let metric): metric.kind.fullTitle
        }
    }

    var descriptionText: String {
        switch subject {
        case .totalMarketCap: Localization.marketCryptoTotalCapInfo
        case .index(let metric): metric.kind.info
        }
    }

    var reading: MarketCapViewModel.Metric? {
        switch subject {
        case .totalMarketCap: nil
        case .index(let metric): metric
        }
    }

    init(subject: MarketCapInfoSubject, closeAction: @escaping () -> Void) {
        self.subject = subject
        self.closeAction = closeAction
    }
}

enum MarketCapInfoSubject {
    case totalMarketCap
    case index(MarketCapViewModel.Metric)
}
