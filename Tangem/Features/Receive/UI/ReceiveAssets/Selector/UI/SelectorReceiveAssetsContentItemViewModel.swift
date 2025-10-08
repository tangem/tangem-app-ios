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
    // MARK: - Properties

    let stateView: StateView
    let pageAssetIndexUpdateNotifier = PassthroughSubject<Int, Never>()

    // MARK: - Init

    init(stateView: StateView) {
        self.stateView = stateView
    }
}

extension SelectorReceiveAssetsContentItemViewModel {
    enum StateView {
        case address([SelectorReceiveAssetsAddressPageItemViewModel])
        case domain([SelectorReceiveAssetsDomainItemViewModel])
    }
}
