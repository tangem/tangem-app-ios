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
import TangemUI
import TangemLocalization
import TangemUIUtils

final class ArchivedAccountsViewModel: ObservableObject {
    private typealias LoadingState = LoadingValue<[ArchivedCryptoAccountInfo]>

    // MARK: - State

    @Published var viewState = LoadingState.loading

    // MARK: - Dependencies

    private let accountModelsManager: AccountModelsManager
    private weak var coordinator: RecoverableAccountRoutable?

    // MARK: - Alerts

    @Published var alertBinder: AlertBinder?

    // MARK: - Internal state

    private var recoverAccountTask: Task<Void, Never>?

    // MARK: - Init

    init(accountModelsManager: AccountModelsManager, coordinator: RecoverableAccountRoutable?) {
        self.accountModelsManager = accountModelsManager
        self.coordinator = coordinator
    }

    // MARK: - ViewData

    func makeAccountIconViewData(for model: ArchivedCryptoAccountInfo) -> AccountIconView.ViewData {
        AccountModelUtils.UI.iconViewData(icon: model.icon, accountName: model.name)
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
        recoverAccountTask?.cancel()
        recoverAccountTask = runTask(in: self) { viewModel in
            do {
                try await viewModel.accountModelsManager.unarchiveCryptoAccount(info: accountInfo)
                await viewModel.handleAccountRecoverySuccess()
            } catch {
                await viewModel.handleAccountRecoveryFailure(accountInfo: accountInfo, error: error)
            }
        }
    }

    // MARK: - Private implementation

    @MainActor
    private func handleAccountRecoverySuccess() {
        coordinator?.close()

        Toast(view: SuccessToast(text: Localization.accountRecoverSuccessMessage))
            .present(layout: .top(padding: 24), type: .temporary(interval: 4))
    }

    @MainActor
    private func handleAccountRecoveryFailure(accountInfo: ArchivedCryptoAccountInfo, error: Error) {
        alertBinder = AlertBuilder.makeAlert(
            title: Localization.accountArchivedRecoverErrorTitle,
            message: Localization.accountArchivedRecoverErrorMessage,
            primaryButton: .default(Text(Localization.commonGotIt))
        )

        AccountsLogger.error("Failed to recover archived account with info \(accountInfo)", error: error)
    }
}
