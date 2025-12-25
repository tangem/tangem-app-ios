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
import TangemUIUtils
import TangemLocalization

final class ArchivedAccountsViewModel: ObservableObject {
    private typealias LoadingState = LoadingResult<[ArchivedCryptoAccountInfo], AccountModelsManagerError>

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

    func makeAccountRowViewData(for model: ArchivedCryptoAccountInfo) -> ArchivedAccountRowView.ViewData {
        let tokensString = Localization.commonTokensCount(model.tokensCount)
        let networksString = Localization.commonNetworksCount(model.networksCount)
        let subtitle = Localization.accountLabelTokensInfo(tokensString, networksString)

        return ArchivedAccountRowView.ViewData(
            iconData: AccountModelUtils.UI.iconViewData(icon: model.icon, accountName: model.name),
            name: model.name,
            subtitle: subtitle,
            isRecovering: recoveringAccountId == model.id,
            isRecoverDisabled: recoveringAccountId != nil,
            onRecover: { [weak self] in
                self?.recoverAccount(model)
            }
        )
    }

    @MainActor
    func fetchArchivedAccounts() async {
        do throws(AccountModelsManagerError) {
            viewState = .loading
            let archivedAccounts = try await accountModelsManager.archivedCryptoAccountInfos()
            viewState = .success(archivedAccounts)
        } catch {
            viewState = .failure(error)
        }
    }

    func onAppear() {
        Analytics.log(.walletSettingsArchivedAccountsScreenOpened)
    }

    func recoverAccount(_ accountInfo: ArchivedCryptoAccountInfo) {
        Analytics.log(.walletSettingsButtonRecoverAccount)
        recoverAccountTask?.cancel()
        recoveringAccountId = accountInfo.id

        recoverAccountTask = Task { [weak self] in
            do throws(AccountRecoveryError) {
                guard let result = try await self?.accountModelsManager.unarchiveCryptoAccount(info: accountInfo) else {
                    return
                }

                await self?.handleAccountRecoverySuccess(result: result)
            } catch {
                await self?.handleAccountRecoveryFailure(accountInfo: accountInfo, error: error)
            }
        }
    }

    // MARK: - Private implementation

    @MainActor
    private func handleAccountRecoverySuccess(result: AccountOperationResult) {
        recoveringAccountId = nil
        coordinator?.close(with: result)

        Analytics.log(.walletSettingsAccountRecovered)

        Toast(view: SuccessToast(text: Localization.accountRecoverSuccessMessage))
            .present(layout: .top(padding: 24), type: .temporary(interval: 4))
    }

    @MainActor
    private func handleAccountRecoveryFailure(accountInfo: ArchivedCryptoAccountInfo, error: AccountRecoveryError) {
        recoveringAccountId = nil

        let title: String
        let message: String
        let buttonText: String

        switch error {
        case .tooManyAccounts:
            title = Localization.accountArchivedRecoverErrorTitle
            message = Localization.accountRecoverLimitDialogDescription(AccountModelUtils.maxNumberOfAccounts)
            buttonText = Localization.commonGotIt
        case .duplicateAccountName:
            title = Localization.accountFormNameAlreadyExistErrorTitle
            message = Localization.accountFormNameAlreadyExistErrorDescription
            buttonText = Localization.commonGotIt
        case .unknownError:
            title = Localization.commonSomethingWentWrong
            message = Localization.accountGenericErrorDialogMessage
            buttonText = Localization.commonOk
        }

        alertBinder = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: title,
            message: message,
            buttonText: buttonText
        )

        AccountsLogger.error("Failed to recover archived account with info \(accountInfo)", error: error)
    }
}
