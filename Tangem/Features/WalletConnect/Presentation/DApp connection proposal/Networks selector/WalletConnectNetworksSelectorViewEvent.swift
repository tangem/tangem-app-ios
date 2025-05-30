//
//  WalletConnectNetworksSelectorViewEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectNetworksSelectorViewEvent {
    case navigationBackButtonTapped
    case optionalBlockchainSelectionChanged(index: Int, isSelected: Bool)
    case doneButtonTapped
}
