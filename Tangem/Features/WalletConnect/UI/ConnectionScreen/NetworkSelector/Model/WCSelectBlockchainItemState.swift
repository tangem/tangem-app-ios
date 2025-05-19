//
//  WCSelectBlockchainItemState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WCSelectBlockchainItemState {
    // blockchain is optional. User wallet does NOT contain it. Can connect to dApp.
    // listed in "Not added" UI section.
    case notAdded2

    // blockchain is optional. User wallet does contain it. Can connect to dApp.
    // listed in "Available networks" UI section as NOT SELECTED.
    case notSelected2

    // blockchain is optional. User wallet does contain it. Can connect to dApp.
    // listed in "Available networks" UI section as SELECTED.
    case selected2

    // blockchain is required. User wallet does contain it. Can connect to dApp.
    // listed in "Available networks" UI section as SELECTED (Switch is always readonly).
    case required2

    // blockchain is required. User wallet does NOT contain it. Can't connect to dApp
    // listed in top warning with blockchain name.
    case requiredToAdd2
}
