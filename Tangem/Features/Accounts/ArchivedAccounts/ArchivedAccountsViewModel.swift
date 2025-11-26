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
import TangemUI
import TangemLocalization
import TangemUIUtils

final class ArchivedAccountsViewModel: ObservableObject {
    private typealias LoadingState = LoadingValue<[ArchivedCryptoAccountInfo]>

    // MARK: - State

    @Published var viewState = LoadingState.loading
    @Published private(set) var recoveringAccountId: ArchivedCryptoAccountInfo.ID?

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

    deinit {
        recoverAccountTask?.cancel()
    }

    // MARK: - ViewData

    func makeAccountRowData(for model: ArchivedCryptoAccountInfo) -> AccountRowViewModel.Input {
        ArchivedAccountInfoToAccountRowDataMapper.map(model)
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
        recoveringAccountId = accountInfo.id

        recoverAccountTask = Task { [weak self] in
            do throws(AccountRecoveryError) {
                try await self?.accountModelsManager.unarchiveCryptoAccount(info: accountInfo)
                await self?.handleAccountRecoverySuccess()
            } catch {
                await self?.handleAccountRecoveryFailure(accountInfo: accountInfo, error: error)
            }
        }
    }

    // MARK: - Private implementation

    @MainActor
    private func handleAccountRecoverySuccess() {
        recoveringAccountId = nil
        coordinator?.close()

        Toast(view: SuccessToast(text: Localization.accountRecoverSuccessMessage))
            .present(layout: .top(padding: 24), type: .temporary(interval: 4))
    }

    @MainActor
    private func handleAccountRecoveryFailure(accountInfo: ArchivedCryptoAccountInfo, error: AccountRecoveryError) {
        recoveringAccountId = nil

        let message: String
        let buttonTitle: String

        switch error {
        case .tooManyActiveAccounts:
            message = Localization.accountRecoverLimitDialogDescription(AccountModelUtils.maxNumberOfAccounts)
            buttonTitle = Localization.commonGotIt

        case .unknownError:
            message = Localization.commonSomethingWentWrong
            buttonTitle = Localization.commonOk
        }

        alertBinder = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: Localization.accountArchivedRecoverErrorTitle,
            message: message,
            buttonText: buttonTitle
        )

        AccountsLogger.error("Failed to recover archived account with info \(accountInfo)", error: error)
    }
}
