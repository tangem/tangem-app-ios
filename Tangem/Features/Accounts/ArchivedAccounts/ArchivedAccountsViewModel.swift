//
//  ArchivedAccountsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemAccounts
import SwiftUI

final class ArchivedAccountsViewModel: ObservableObject {
    private typealias LoadingState = LoadingValue<[ArchivedCryptoAccountInfo]>

    // MARK: - State

    @Published var viewState = LoadingState.loading

    // MARK: - Dependencies

    private let accountModelsManager: AccountModelsManager
    private weak var coordinator: RecoverableAccountRoutable?

    // MARK: - Init

    init(accountModelsManager: AccountModelsManager, coordinator: RecoverableAccountRoutable?) {
        self.accountModelsManager = accountModelsManager
        self.coordinator = coordinator
    }

    // MARK: - ViewData

    func makeAccountIconBackgroundColor(for model: ArchivedCryptoAccountInfo) -> Color {
        AccountModelUtils.UI.iconColor(from: model.icon.color)
    }

    func makeNameMode(for model: ArchivedCryptoAccountInfo) -> AccountIconView.NameMode {
        AccountModelUtils.UI.nameMode(from: model.icon.name, accountName: model.name)
    }

    @MainActor
    func fetchArchivedAccounts() async {
        do {
            viewState = .loading
            let archivedAccounts = try await accountModelsManager.archivedCryptoAccountInfos()
            viewState = .loaded(archivedAccounts)
        } catch {
            viewState = .failedToLoad(error: error)
        }
    }

    func recoverAccount(_ accountInfo: ArchivedCryptoAccountInfo) {
        coordinator?.recoverAccount { [weak self] in
            try self?.accountModelsManager.unarchiveCryptoAccount(info: accountInfo)
        }
    }
}
