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

    var pageAssetIndex: Int = 0
    let pageAssetIndexUpdateNotifier = PassthroughSubject<Int, Never>()

    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(viewState: ViewState) {
        self.viewState = viewState

        bind()
    }

    private func bind() {
        pageAssetIndexUpdateNotifier
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, index in
                viewModel.pageAssetIndex = index
            }
            .store(in: &bag)
    }
}

extension SelectorReceiveAssetsContentItemViewModel {
    enum ViewState {
        case address([SelectorReceiveAssetsAddressPageItemViewModel])
        case domain([SelectorReceiveAssetsDomainItemViewModel])
    }
}
