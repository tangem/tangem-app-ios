//
//  SelectorReceiveAssetsContentItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets

class SelectorReceiveAssetsContentItemViewModel: Identifiable {
    let stateView: StateView

    // MARK: - Init

    init(stateView: StateView) {
        self.stateView = stateView
    }
}

extension SelectorReceiveAssetsContentItemViewModel {
    enum StateView {
        case address(SelectorReceiveAssetsAddressItemViewModel)
        case domain(SelectorReceiveAssetsDomainItemViewModel)
    }
}
