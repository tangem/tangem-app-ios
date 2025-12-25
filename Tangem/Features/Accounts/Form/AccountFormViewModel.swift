//
//  AccountFormViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import CombineExt
import Combine
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccounts
import TangemFoundation

final class AccountFormViewModel: ObservableObject, Identifiable {
    // MARK: - Dynamic State

    @Published var accountName: String

    @Published var selectedColor: GridItemColor<AccountModel.Icon.Color>
    @Published var selectedIcon: GridItemImage<AccountModel.Icon.Name>
    @Published var alert: AlertBinder?
    @Published var isLoading: Bool = false
    @Published private var totalAccountsCount: Int = 0

    // MARK: - Static state

    var maxNameLength: Int { AccountModelUtils.maxAccountNameLength }

    var description: String? {
        switch flowType {
        case .edit(let account):
            // [REDACTED_TODO_COMMENT]
            if let cryptoAccount = account as? any CryptoAccountModel {
                return cryptoAccount.descriptionString
            }

            return nil

        case .create:
            return Localization.accountFormAccountIndex(totalAccountsCount)
        }
    }

    let colors: [GridItemColor] = AccountModel.Icon.Color
        .allCases
        .map { iconColor in
            let color = AccountModelUtils.UI.iconColor(from: iconColor)

            return GridItemColor(id: iconColor, color: color)
        }

    let images: [GridItemImage] = AccountModel.Icon.Name.allCases
        .sorted()
        .map { iconName in
            let image = AccountModelUtils.UI.iconAsset(from: iconName)
            let kind: GridItemImageKind = iconName == .letter ? .letter(visualImageRepresentation: image) : .image(image)

            return GridItemImage(id: iconName, kind: kind)
        }

    // MARK: - Private

    private var nameMode: AccountIconView.NameMode {
        switch selectedIcon.kind {
        case .image(let imageType):
            return .imageType(imageType)

        case .letter:
            if let firstLetter = accountName.first {
                return .letter(String(firstLetter))
            }

            return .imageType(
                Assets.tangemIcon,
                AccountIconView.NameMode.ImageConfig(opacity: 0.4)
            )
        }
    }

    private var accountIcon: AccountModel.Icon {
        AccountModel.Icon(name: selectedIcon.id, color: selectedColor.id)
    }

    private var activeTask: AnyCancellable?

    // MARK: - Dependencies

    private let initialStateSnapshot: StateSnapshot
    private let flowType: FlowType
    private let closeAction: (AccountOperationResult) -> Void
    private let accountModelsManager: AccountModelsManager

    private var bag = Set<AnyCancellable>()

    init(
        accountModelsManager: AccountModelsManager,
        flowType: FlowType,
        closeAction: @escaping (AccountOperationResult) -> Void
    ) {
        let accountName: String
        let iconColor: AccountModel.Icon.Color
        let iconName: AccountModel.Icon.Name

        switch flowType {
        case .edit(let account):
            iconColor = account.icon.color
            iconName = account.icon.name
            accountName = account.name
        case .create:
            let newAccountIcon = AccountModelUtils.UI.newAccountIcon()
            iconColor = newAccountIcon.color
            iconName = newAccountIcon.name
            accountName = ""
        }

        let selectedColor = GridItemColor(
            id: iconColor,
            color: AccountModelUtils.UI.iconColor(from: iconColor)
        )

        let selectedIcon = GridItemImage(
            id: iconName,
            kind: Self.gridItemImageKind(from: iconName)
        )

        self.accountName = accountName
        self.selectedColor = selectedColor
        self.selectedIcon = selectedIcon
        self.flowType = flowType
        self.closeAction = closeAction
        self.accountModelsManager = accountModelsManager

        initialStateSnapshot = StateSnapshot(name: accountName, color: selectedColor, image: selectedIcon)

        setupDescription()
    }

    deinit {
        activeTask?.cancel()
    }

    // MARK: - ViewData

    var iconViewData: AccountIconView.ViewData {
        // Can't use `AccountModelUtils.UI.iconViewData(icon:accountName:)` here because of
        // slightly different logic of `nameMode` creation, see `nameMode` property implementation
        AccountIconView.ViewData(
            backgroundColor: AccountModelUtils.UI.iconColor(from: selectedColor.id),
            nameMode: nameMode
        )
    }

    var placeholder: String {
        switch flowType {
        case .edit:
            Localization.accountFormPlaceholderEditAccount
        case .create:
            Localization.accountFormPlaceholderNewAccount
        }
    }

    var mainButtonDisabled: Bool {
        accountName.isEmpty
    }

    var title: String {
        switch flowType {
        case .edit:
            Localization.accountFormTitleEdit
        case .create:
            Localization.accountFormTitleCreate
        }
    }

    var buttonTitle: String {
        switch flowType {
        case .edit:
            Localization.commonSave
        case .create:
            Localization.accountFormTitleCreate
        }
    }

    // MARK: - Actions

    func onAppear() {
        if case .edit = flowType {
            Analytics.log(.accountSettingsEditScreenOpened)
        }
    }

    @MainActor
    func onMainButtonTap() {
        logMainButtonAnalytics()

        activeTask = runTask(in: self) { viewModel in
            viewModel.isLoading = true
            defer { viewModel.isLoading = false }

            let result: AccountOperationResult

            do throws(AccountEditError) {
                switch viewModel.flowType {
                case .edit(let account):
                    try await viewModel.editAccount(account: account)
                    // Tokens redistribution can't be performed when editing an existing account
                    result = .none
                case .create:
                    result = try await viewModel.accountModelsManager.addCryptoAccount(
                        name: viewModel.accountName,
                        icon: viewModel.accountIcon
                    )
                }
                viewModel.handleFlowSuccess(result: result)
            } catch {
                viewModel.handleFlowFailure(error: error)
            }
        }.eraseToAnyCancellable()
    }

    private func logMainButtonAnalytics() {
        switch flowType {
        case .edit:
            Analytics.log(event: .accountSettingsButtonSave, params: [
                .accountName: accountName,
                .accountColor: selectedColor.id.rawValue,
                .accountIcon: selectedIcon.id.rawValue,
            ])
        case .create:
            Analytics.log(event: .accountSettingsButtonAddNewAccount, params: [
                .accountName: accountName,
                .accountColor: selectedColor.id.rawValue,
                .accountIcon: selectedIcon.id.rawValue,
                // In analytics this field is named "Derivation", but in the form we don't want to
                // expose any knowledge about derivation — as far as we're concerned, it's the account's ordinal number
                .derivation: String(totalAccountsCount),
            ])
        }
    }

    func onClose() {
        let currentSnapshot = StateSnapshot(name: accountName, color: selectedColor, image: selectedIcon)

        if currentSnapshot != initialStateSnapshot {
            let message = switch flowType {
            case .edit:
                Localization.accountUnsavedDialogMessageEdit
            case .create:
                Localization.accountUnsavedDialogMessageCreate
            }

            alert = makeExitAlert(message: message)
        } else {
            // No changes were made, no tokens redistribution performed
            close(result: .none)
        }
    }

    // MARK: - Private

    private func editAccount(account: any BaseAccountModel) async throws(AccountEditError) {
        let currentSnapshot = StateSnapshot(name: accountName, color: selectedColor, image: selectedIcon)

        try await account.edit { editor in
            if currentSnapshot.name != initialStateSnapshot.name {
                editor.setName(accountName)
            }
            if currentSnapshot.color != initialStateSnapshot.color || currentSnapshot.image != initialStateSnapshot.image {
                editor.setIcon(accountIcon)
            }
        }
    }

    private func close(result: AccountOperationResult) {
        activeTask?.cancel()
        closeAction(result)
    }

    @MainActor
    private func handleFlowSuccess(result: AccountOperationResult) {
        let toastText: String

        switch flowType {
        case .edit:
            toastText = Localization.accountEditSuccessMessage
        case .create:
            Analytics.log(.walletSettingsAccountCreated)
            toastText = Localization.accountCreateSuccessMessage
        }

        close(result: result)

        Toast(view: SuccessToast(text: toastText))
            .present(layout: .top(padding: 24), type: .temporary(interval: 4))
    }

    @MainActor
    private func handleFlowFailure(error: AccountEditError) {
        let source: Analytics.ParameterValue
        switch flowType {
        case .edit: source = .accountSourceEdit
        case .create: source = .accountSourceNew
        }

        Analytics.log(event: .accountSettingsAccountError, params: [
            .source: source.rawValue,
            .errorDescription: String(describing: error),
        ])

        let title: String
        let message: String
        let buttonText: String

        switch error {
        case .tooManyAccounts:
            title = Localization.accountAddLimitDialogTitle
            message = Localization.accountAddLimitDialogDescription(AccountModelUtils.maxNumberOfAccounts)
            buttonText = Localization.commonGotIt
        case .duplicateAccountName:
            title = Localization.accountFormNameAlreadyExistErrorTitle
            message = Localization.accountFormNameAlreadyExistErrorDescription
            buttonText = Localization.commonGotIt
        case .accountNameTooLong,
             .missingAccountName:
            // These two errors should never be thrown because this VM validates account name before trying to edit/create an account
            fallthrough
        case .unknownError:
            title = Localization.commonSomethingWentWrong
            message = Localization.accountGenericErrorDialogMessage
            buttonText = Localization.commonOk
        }

        alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: title,
            message: message,
            buttonText: buttonText
        )
    }

    private func setupDescription() {
        guard case .create = flowType else { return }

        accountModelsManager.totalAccountsCountPublisher
            .receiveOnMain()
            .assign(to: &$totalAccountsCount)
    }

    private static func gridItemImageKind(from accountIconName: AccountModel.Icon.Name) -> GridItemImageKind {
        switch accountIconName {
        case .letter:
            return .letter(visualImageRepresentation: Assets.Accounts.letter)
        default:
            return .image(AccountModelUtils.UI.iconAsset(from: accountIconName))
        }
    }

    // MARK: - Alerts and toasts

    private func makeExitAlert(message: String) -> AlertBinder {
        AlertBuilder.makeExitAlert(
            title: Localization.accountUnsavedDialogTitle,
            message: message,
            keepEditingButtonText: Localization.accountUnsavedDialogActionFirst,
            discardButtonText: Localization.accountUnsavedDialogActionSecond,
            discardAction: { [weak self] in
                // No changes were made, no tokens redistribution performed
                self?.close(result: .none)
            }
        )
    }
}

extension AccountFormViewModel {
    enum FlowType {
        case edit(account: any BaseAccountModel)
        case create(CreatedAccountType)
    }
}

extension AccountFormViewModel.FlowType {
    enum CreatedAccountType {
        case crypto

        @available(*, unavailable, message: "This account type is not implemented yet")
        case smart

        @available(*, unavailable, message: "This account type is not implemented yet")
        case visa
    }
}

extension AccountFormViewModel {
    struct StateSnapshot: Equatable {
        let name: String
        let color: GridItemColor<AccountModel.Icon.Color>
        let image: GridItemImage<AccountModel.Icon.Name>
    }
}
