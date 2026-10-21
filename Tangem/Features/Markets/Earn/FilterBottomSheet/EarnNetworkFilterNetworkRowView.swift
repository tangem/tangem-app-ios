//
//  EarnNetworkFilterNetworkRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnNetworkFilterNetworkRowInput: Identifiable {
    let id: String
    let iconAsset: ImageType
    let networkName: String
    let currencySymbol: String
    let isSelected: Bool
    let onTap: () -> Void
}
