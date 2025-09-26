//
//  SendStepNavigationTrailingViewType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum SendStepNavigationTrailingViewType: Hashable {
    case closeButton
    case qrCodeButton(action: () -> Void)
    case dotsButton(action: () -> Void)

    static func == (lhs: SendStepNavigationTrailingViewType, rhs: SendStepNavigationTrailingViewType) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .closeButton:
            hasher.combine("closeButton")
        case .qrCodeButton:
            hasher.combine("qrCodeButton")
        case .dotsButton:
            hasher.combine("dotsButton")
        }
    }
}
