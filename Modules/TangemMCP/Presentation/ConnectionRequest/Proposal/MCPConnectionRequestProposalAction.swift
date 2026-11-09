//
//  MCPConnectionRequestProposalAction.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct TangemFoundation.UserWalletId

enum MCPConnectionRequestProposalAction {
    case fetchInitiated
    case fetchSucceeded(MCPConnectionRequest)

    case userWalletSelectorTapped
    case userWalletSelectionUpdated(MCPUserWallet)

    case applicationWillEnterForeground
    case openSystemSettingsButtonTapped

    case navigationCloseButtonTapped
    case declineButtonTapped
    case connectButtonTapped
}
