//
//  MCPConnectionRequestUserWalletSelectorRowAction.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class UIKit.UIImage

enum MCPConnectionRequestUserWalletSelectorRowAction {
    case viewDidLoad
    case viewTapped

    case imageLoaded(UIImage)
    case balanceUpdated(String)

    case isSelectedChanged(Bool)
}
