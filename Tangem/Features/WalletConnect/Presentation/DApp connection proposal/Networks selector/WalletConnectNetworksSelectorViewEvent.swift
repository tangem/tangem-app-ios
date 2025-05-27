//
//  WalletConnectNetworksSelectorViewEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

enum WalletConnectNetworksSelectorViewEvent {
    case navigationBackButtonTapped
    case optionalBlockchainSelectionChanged(Blockchain)
    case doneButtonTapped
}
