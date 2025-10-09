//
//  TokenAlertReceiveAssetsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt
import TangemUI
import TangemAssets

final class TokenAlertReceiveAssetsViewModel: ObservableObject, Identifiable {
    // MARK: - UI Properties

    let tokenIconInfo: TokenIconInfo
    let tokenId: String?
    let networkName: String
    let currencySymbol: String

    // MARK: - Private Properties

    private var proxySelectorViewModel: SelectorReceiveAssetsViewModel
    private weak var coordinator: TokenAlertReceiveAssetsRoutable?

    // MARK: - Init

    init(
        tokenItem: TokenItem,
        selectorViewModel: SelectorReceiveAssetsViewModel,
        coordinator: TokenAlertReceiveAssetsRoutable?
    ) {
        proxySelectorViewModel = selectorViewModel
        self.coordinator = coordinator

        tokenIconInfo = TokenIconInfoBuilder().build(from: tokenItem, isCustom: false)
        tokenId = tokenItem.id
        networkName = tokenItem.blockchain.displayName.capitalizingFirstLetter()
        currencySymbol = tokenItem.currencySymbol
    }

    func onViewAppear() {
        // [REDACTED_TODO_COMMENT]
    }

    // MARK: - Implementation

    func onGotItTapAction() {
        coordinator?.routeOnSelectorReceiveAssets(with: proxySelectorViewModel)
    }
}
