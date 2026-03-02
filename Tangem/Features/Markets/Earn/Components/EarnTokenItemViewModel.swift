//
//  EarnTokenItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

// MARK: - EarnTokenItemViewModel

struct EarnTokenItemViewModel: Identifiable, Hashable {
    let onTapAction: () -> Void

    var id: String {
        [token.id, token.symbol, networkName, token.earnType.rawValue].joined(separator: "_")
    }

    var name: String { token.name }
    var symbol: String { token.symbol }
    var earnType: EarnType { token.earnType }

    var networkName: String { token.networkName }

    var imageUrl: URL? { token.imageUrl }

    var rateText: String { token.rateText }

    var blockchainIconAsset: ImageType? { token.blockchainIconAsset }

    private let token: EarnTokenModel

    init(token: EarnTokenModel, onTapAction: @escaping () -> Void) {
        self.token = token
        self.onTapAction = onTapAction
    }

    static func == (lhs: EarnTokenItemViewModel, rhs: EarnTokenItemViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
