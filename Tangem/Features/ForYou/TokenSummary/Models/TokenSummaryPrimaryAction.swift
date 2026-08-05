//
//  TokenSummaryPrimaryAction.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct TokenSummaryPrimaryAction: Equatable {
    let kind: Kind
    let isEnabled: Bool

    init(kind: Kind, isEnabled: Bool) {
        self.kind = kind
        self.isEnabled = isEnabled
    }

    var title: String {
        switch kind {
        case .goToSwap: Localization.tokenSummaryGoToSwapButton
        case .addFunds: Localization.commonAddFunds
        }
    }
}

extension TokenSummaryPrimaryAction {
    enum Kind: Equatable {
        case goToSwap
        case addFunds
    }

    static func goToSwap(isEnabled: Bool) -> Self {
        .init(kind: .goToSwap, isEnabled: isEnabled)
    }

    static let addFunds = Self(kind: .addFunds, isEnabled: true)
}
