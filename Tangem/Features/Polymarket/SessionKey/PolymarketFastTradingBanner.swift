//
//  PolymarketFastTradingBanner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PolymarketFastTradingBanner: Equatable {
    case foreignSigners
    case activate
    case extend(daysLeft: Int)

    init?(state: PolymarketFastTradingState, includingForeignSigners: Bool, isDismissed: (DismissibleKind) -> Bool) {
        guard case .loaded(let assessment) = state else {
            return nil
        }

        if includingForeignSigners, assessment.hasForeignSigners {
            self = .foreignSigners
            return
        }

        guard let authorization = PolymarketFastTradingAuthorization(assessment: assessment) else {
            return nil
        }

        let banner: PolymarketFastTradingBanner

        switch authorization {
        case .renew:
            guard
                case .active(let localKey) = assessment.status,
                let daysLeft = PolymarketFastTradingAssessment.daysUntilExpiry(of: localKey, now: assessment.now)
            else {
                return nil
            }

            banner = .extend(daysLeft: daysLeft)
        case .enable, .reenable, .repair, .replace:
            banner = .activate
        }

        if let kind = banner.dismissibleKind, isDismissed(kind) {
            return nil
        }

        self = banner
    }

    var dismissibleKind: DismissibleKind? {
        switch self {
        case .foreignSigners: nil
        case .activate: .activate
        case .extend: .extend
        }
    }
}

// MARK: - Dismissible kind

extension PolymarketFastTradingBanner {
    enum DismissibleKind: String, CaseIterable {
        case activate = "activate_banner"
        case extend = "extend_banner"

        var dismissalPeriod: TimeInterval {
            switch self {
            case .activate: 30 * 24 * 60 * 60
            case .extend: 24 * 60 * 60
            }
        }

        func isDismissed(dismissedAt: Date?, now: Date) -> Bool {
            guard let dismissedAt else { return false }

            return now < dismissedAt.addingTimeInterval(dismissalPeriod)
        }
    }
}

// MARK: - Routing

protocol PolymarketFastTradingBannerRoutable: AnyObject {
    @MainActor
    func openSettings()

    @MainActor
    func openFastTradingActivation()
}

extension PolymarketFastTradingBannerRoutable {
    @MainActor
    func open(_ banner: PolymarketFastTradingBanner) {
        switch banner {
        case .foreignSigners:
            openSettings()
        case .activate, .extend:
            openFastTradingActivation()
        }
    }
}
