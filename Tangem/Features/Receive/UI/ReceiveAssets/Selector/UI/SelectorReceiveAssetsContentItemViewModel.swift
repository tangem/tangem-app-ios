//
//  SelectorReceiveAssetsContentItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets

final class SelectorReceiveAssetsContentItemViewModel: Identifiable {
    // MARK: - Properties

    let viewState: ViewState
    let pageAssetIndexUpdateNotifier = PassthroughSubject<Int, Never>()

    // MARK: - Init

    init(viewState: ViewState) {
        self.viewState = viewState
    }
}

extension SelectorReceiveAssetsContentItemViewModel {
    enum ViewState {
        case address([SelectorReceiveAssetsAddressPageItemViewModel])
        case domain([SelectorReceiveAssetsDomainItemViewModel])
    }
}
