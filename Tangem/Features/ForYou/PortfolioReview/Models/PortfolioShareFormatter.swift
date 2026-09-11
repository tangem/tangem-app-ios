//
//  PortfolioShareFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A holding's share of the portfolio, as the review states it in both places it appears: the token row and
/// the donut's selection tooltip. Shared so the two can't drift, which they did while each held its own copy.
struct PortfolioShareFormatter {
    private let percentFormatter = PercentFormatter()

    /// A share too small for the shown digits reads as "< 0.01%" rather than a flat zero, the way the
    /// balance formatter renders an amount below its lowest representable one.
    func string(for share: Decimal) -> String {
        guard share > 0, share < Constants.lowestRepresentableShare else {
            return percentFormatter.format(share, option: Constants.option)
        }

        let lowest = percentFormatter.format(Constants.lowestRepresentableShare, option: Constants.option)
        return "<\(AppConstants.unbreakableSpace)\(lowest)"
    }
}

// MARK: - Constants

extension PortfolioShareFormatter {
    enum Constants {
        static let option: PercentFormatter.Option = .yield

        /// Derived from the option rather than spelled out: a percent is a hundredth, so the two digits the
        /// option shows stop at 0.01%, and a change of that precision moves the threshold with it.
        static let lowestRepresentableShare: Decimal = 1 / pow(10, option.fractionDigits.max + 2)
    }
}
