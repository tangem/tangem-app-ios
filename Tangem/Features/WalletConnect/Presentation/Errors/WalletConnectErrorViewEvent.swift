//
//  WalletConnectErrorViewEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL

enum WalletConnectErrorViewEvent {
    case closeButtonTapped
    case linkTapped(URL)
    case buttonTapped
}
