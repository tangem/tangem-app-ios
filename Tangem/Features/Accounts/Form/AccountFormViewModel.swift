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
    @Published var description: String?
    @Published var isLoading: Bool = false

    // MARK: - Static state

    var maxNameLength: Int { AccountModelUtils.maxAccountNameLength }

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
        let selectedColor: GridItemColor<AccountModel.Icon.Color>
        let selectedIcon: GridItemImage<AccountModel.Icon.Name>

        switch flowType {
        case .edit(let account):
            accountName = account.name
            let accountColor = account.icon.color
            selectedColor = GridItemColor(
                id: accountColor,
                color: AccountModelUtils.UI.iconColor(from: accountColor)
            )

            let gridItemImageKind: GridItemImageKind = switch account.icon.name {
            case .letter:
                .letter(visualImageRepresentation: Assets.Accounts.letter)

            default:
                .image(AccountModelUtils.UI.iconAsset(from: account.icon.name))
            }

            selectedIcon = GridItemImage(id: account.icon.name, kind: gridItemImageKind)

        case .create:
            let randomAccountColor = AccountModelUtils.UI.getRandomIconColor()
            let color = AccountModelUtils.UI.iconColor(from: randomAccountColor)
            selectedColor = GridItemColor(id: randomAccountColor, color: color)
            selectedIcon = GridItemImage(
                id: .letter,
                kind: .letter(visualImageRepresentation: Assets.Accounts.letter)
            )
            accountName = ""
        }

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
        // Can't use `AccountModelUtils.UI.iconColor` here because of slightly different logic of `nameMode` creation
        // see nameMode
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

    @MainActor
    func onMainButtonTap() {
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
            toastText = Localization.accountCreateSuccessMessage
        }

        close(result: result)

        Toast(view: SuccessToast(text: toastText))
            .present(layout: .top(padding: 24), type: .temporary(interval: 4))
    }

    @MainActor
    private func handleFlowFailure(error: AccountEditError) {
        let message: String
        let buttonText: String

        switch error {
        case .tooManyAccounts:
            message = Localization.accountAddLimitDialogDescription(AccountModelUtils.maxNumberOfAccounts)
            buttonText = Localization.commonGotIt
        case .duplicateAccountName:
            message = Localization.accountFormNameAlreadyExistErrorDescription
            buttonText = Localization.commonGotIt
        case .accountNameTooLong,
             .missingAccountName:
            // These two errors should never be thrown because this VM validates account name before trying to edit/create an account
            fallthrough
        case .unknownError:
            message = Localization.accountGenericErrorDialogMessage
            buttonText = Localization.commonOk
        }

        alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: Localization.commonSomethingWentWrong,
            message: message,
            buttonText: buttonText
        )
    }

    private func setupDescription() {
        switch flowType {
        case .edit(let account):
            // [REDACTED_TODO_COMMENT]
            if let cryptoAccount = account as? any CryptoAccountModel {
                description = cryptoAccount.descriptionString
            }

        case .create:
            accountModelsManager.totalAccountsCountPublisher
                .map { Localization.accountFormAccountIndex($0) }
                .receiveOnMain()
                .assign(to: \.description, on: self, ownership: .weak)
                .store(in: &bag)
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
