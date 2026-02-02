//
//  CloreMigrationModuleFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CloreMigrationRoutable: AnyObject {
    func openURLInSystemBrowser(url: URL)
}

protocol CloreMigrationModuleFlowFactory {
    func makeCloreMigrationViewModel() -> CloreMigrationViewModel
}

final class CommonCloreMigrationModuleFlowFactory {
    // MARK: - Dependencies

    private let walletModel: any WalletModel
    private let coordinator: any CloreMigrationRoutable

    // MARK: - Init

    init(walletModel: any WalletModel, coordinator: any CloreMigrationRoutable) {
        self.walletModel = walletModel
        self.coordinator = coordinator
    }
}

extension CommonCloreMigrationModuleFlowFactory: CloreMigrationModuleFlowFactory {
    func makeCloreMigrationViewModel() -> CloreMigrationViewModel {
        CloreMigrationViewModel(
            userWalletId: walletModel.userWalletId,
            accountId: walletModel.account?.id.walletConnectIdentifierString,
            tokenItem: walletModel.tokenItem,
            coordinator: coordinator
        )
    }
}
