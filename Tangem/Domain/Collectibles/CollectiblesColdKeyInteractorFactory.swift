//
//  CollectiblesColdKeyInteractorFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// - Warning: A long-lived holder must keep the factory rather than an interactor, which freezes the session filter
/// and the SDK configuration it was made with.
final class CollectiblesColdKeyInteractorFactory {
    private weak var userWalletModel: (any UserWalletModel)?

    init(userWalletModel: (any UserWalletModel)? = nil) {
        self.userWalletModel = userWalletModel
    }

    func configure(with userWalletModel: any UserWalletModel) {
        self.userWalletModel = userWalletModel
    }

    func makeInteractor() -> CollectiblesColdKeyInteractor {
        userWalletModel?.collectiblesColdKeyInteractor ?? UnavailableCollectiblesColdKeyInteractor()
    }
}
