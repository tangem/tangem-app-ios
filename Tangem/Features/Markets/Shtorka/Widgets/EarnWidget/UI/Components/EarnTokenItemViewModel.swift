//
//  EarnTokenItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - EarnTokenItemViewModel

struct EarnTokenItemViewModel: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let imageUrl: URL?
    let networkName: String
    let networkImageUrl: URL?
    let rateValue: Decimal
    let rateType: RateType
    let earnType: EarnType
    let onTapAction: () -> Void

    init(token: EarnTokenModel, onTapAction: @escaping () -> Void) {
        id = token.id
        name = token.name
        symbol = token.symbol
        imageUrl = token.imageUrl
        networkName = token.networkName
        networkImageUrl = token.networkImageUrl
        rateValue = token.rateValue
        rateType = token.rateType
        earnType = token.earnType
        self.onTapAction = onTapAction
    }

    static func == (lhs: EarnTokenItemViewModel, rhs: EarnTokenItemViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
