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
    let networkName: String

    var networkIconImageAsset: ImageType { imageAsset }

    // MARK: - Private Properties

    private let imageAsset: ImageType

    private let blockchainIconProvider = NetworkImageProvider()

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

        let imageUrl: URL?

        if let id = tokenItem.id {
            imageUrl = IconURLBuilder().tokenIconURL(id: id)
        } else {
            imageUrl = nil
        }

        tokenIconInfo = TokenIconInfo(
            name: "",
            blockchainIconAsset: nil,
            imageURL: imageUrl,
            isCustom: false,
            customTokenColor: tokenItem.token?.customTokenColor,
        )

        networkName = tokenItem.blockchain.displayName.capitalizingFirstLetter()
        imageAsset = blockchainIconProvider.provide(by: tokenItem.blockchainNetwork.blockchain, filled: true)
    }

    func onViewAppear() {
        // [REDACTED_TODO_COMMENT]
    }

    // MARK: - Implementation

    func onGotItTapAction() {
        coordinator?.routeOnSelectorReceiveAssets(with: proxySelectorViewModel)
    }
}
