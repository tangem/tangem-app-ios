//
//  ActionButtonsWalletRole.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// How a wallet behaves in the action-buttons feature, vended by each `UserWalletConfig` so the
/// feature layer never sees the underlying card-type taxonomy (single/multi/token/external).
struct ActionButtonsWalletRole {
    let providesHotCryptoTokens: Bool

    /// Pins the Add Funds / Transfer row on the multi-wallet page even when the wallet can't manage tokens (e.g. Nodl).
    let forcesActionButtonsRow: Bool

    /// Makes the buy flow preselect this userWallet's tab in the token selector.
    let preselectsUserWalletInBuy: Bool
}
