//
//  NFTCollectionsCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

//
//  NFTCollectionsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemNFT
import TangemUI

class NFTAssetDetailsCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: NFTAssetDetailsViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = NFTAssetDetailsViewModel(
            asset: options.asset,
            coordinator: self
        )
    }
}

// MARK: - Options

extension NFTAssetDetailsCoordinator {
    struct Options {
        let asset: NFTAsset
    }
}

// MARK: - NFTAssetDetailsRoutable

extension NFTAssetDetailsCoordinator: NFTAssetDetailsRoutable {
    func openSend() {
        // [REDACTED_TODO_COMMENT]
    }

    func openInfo(with text: String) {
        // [REDACTED_TODO_COMMENT]
    }

    func openTraits(with data: KeyValuePanelConfig) {
        // [REDACTED_TODO_COMMENT]
    }
}
