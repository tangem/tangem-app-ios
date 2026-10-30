//
//  SigningActionButtonViewType.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAssets

public enum SigningActionButtonViewType: Hashable, Sendable {
    case requiredNFCInteraction
    case holdToConfirm
}

// MARK: - Main button icon

public extension SigningActionButtonViewType {
    var mainButtonIcon: MainButton.Icon? {
        switch self {
        case .requiredNFCInteraction: .trailing(Assets.tangemIcon)
        case .holdToConfirm: nil
        }
    }
}
