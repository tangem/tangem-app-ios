//
//  SendReceiveTokenNetworkSelectorNetworkViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct SendReceiveTokenNetworkSelectorNetworkViewData: Identifiable {
    let id: String
    let iconURL: URL
    let name: String
    let symbol: String
    let tapAction: () -> Void
}
