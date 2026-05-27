//
//  SelectorReceiveAssetsContentItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class SelectorReceiveAssetsContentItemViewModel: Identifiable {
    // MARK: - Properties

    let viewState: ViewState

    private(set) var pageAssetIndex: Int = 0

    // MARK: - Init

    init(viewState: ViewState) {
        self.viewState = viewState
    }

    func updatePageIndex(_ index: Int) {
        pageAssetIndex = index
    }
}

extension SelectorReceiveAssetsContentItemViewModel {
    enum ViewState {
        case address([SelectorReceiveAssetsAddressPageItemViewModel])
        case domain([SelectorReceiveAssetsDomainItemViewModel])
    }
}
