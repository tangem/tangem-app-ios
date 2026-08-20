//
//  AccountFormViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccounts
import TangemFoundation

final class AccountFormViewModel: ObservableObject, Identifiable {
    // MARK: - Dynamic State

    /// - Note: For use in the UI only, for validation and other logic use `trimmedAccountName` property.
    @Published var accountName: String

    @Published var selectedColor: GridItemColor<AccountModel.CompositeIcon.Color>
    @Published var selectedIcon: GridItemImage<AccountModel.CompositeIcon.Name>
    @Published var alert: AlertBinder?
    @Published var isLoading: Bool = false
    @Published private var totalAccountsCount: Int = 0

    // MARK: - Static state

    var maxNameLength: Int { AccountModelUtils.maxAccountNameLength }

    var description: String? {
        switch flowType {
        case .edit(let account):
            return account.resolve(using: DescriptionResolver())

        case .create:
            return Localization.accountFormAccountIndex(totalAccountsCount)
        }
    }

    let colors: [GridItemColor] = AccountModel.CompositeIcon.Color
        .allCases
        .map { iconColor in
            let color = AccountModelUtils.UI.iconColor(from: iconColor)

            return GridItemColor(id: iconColor, color: color)
        }

    let images: [GridItemImage] = AccountModel.CompositeIcon.Name.allCases
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
            if let firstLetter = trimmedAccountName.first {
                return .letter(String(firstLetter))
            }

            return .imageType(
                Assets.tangemIcon,
                AccountIconView.NameMode.ImageConfig(opacity: 0.4)
            )
        }
    }

    /// - Note: For use in validation and other logic, for UI use `accountName` property.
    private var trimmedAccountName: String {
        accountName.trimmed()
    }

    private var accountIcon: AccountModel.CompositeIcon {
        AccountModel.CompositeIcon(name: selectedIcon.id, color: selectedColor.id)
    }

    private var activeTask: AnyCancellable?

    // MARK: - Dependencies

    private let initialStateSnapshot: StateSnapshot
    private let flowType: FlowType
    private weak var coordinator: AccountFormViewModelRoutable?

    init(
        flowType: FlowType,
        coordinator: AccountFormViewModelRoutable?
    ) {
        let accountName: String
        let iconColor: AccountModel.CompositeIcon.Color
        let iconName: AccountModel.CompositeIcon.Name

        switch flowType {
        case .edit(let account):
            iconColor = account.icon.color
            iconName = account.icon.name
            accountName = account.name
        case .create:
            let newIcon = AccountModelUtils.UI.newAccountIcon()
            iconColor = newIcon.color
            iconName = newIcon.name
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
        self.coordinator = coordinator

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
        .composite(
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
        !AccountModelUtils.isAccountNameValid(trimmedAccountName)
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
        case .create(let creator):
            creator.mainButtonTitle
        }
    }

    // MARK: - Actions

    func onAppear() {
        if case .edit(let account) = flowType {
            let params = account.analyticsParameters(with: SingleAccountAnalyticsBuilder())
            Analytics.log(event: .accountSettingsEditScreenOpened, params: params)
        }
    }

    @MainActor
    func onMainButtonTap() {
        logMainButtonAnalytics()

        activeTask = runTask(in: self) { viewModel in
            viewModel.isLoading = true

            defer { viewModel.isLoading = false }

            let output: AccountFormOperationResult

            do throws(AccountEditError) {
                switch viewModel.flowType {
                case .edit(let account):
                    try await viewModel.editAccount(account: account)
                    // Tokens redistribution can't be performed when editing an existing account
                    output = .crypto(operationResult: .none, createdAccount: nil)
                case .create(let creator):
                    output = try await creator.handleMainButtonTap(
                        name: viewModel.trimmedAccountName,
                        icon: viewModel.accountIcon
                    )
                }
                viewModel.handleFlowSuccess(output)
            } catch {
                viewModel.handleFlowFailure(error: error)
            }
        }.eraseToAnyCancellable()
    }

    private func logMainButtonAnalytics() {
        switch flowType {
        case .edit(let account):
            var params: [Analytics.ParameterKey: String] = [
                .accountName: trimmedAccountName,
                .accountColor: selectedColor.id.rawValue,
                .accountIcon: selectedIcon.id.rawValue,
            ]

            params.enrich(with: account.analyticsParameters(with: SingleAccountAnalyticsBuilder()))
            Analytics.log(event: .accountSettingsButtonSave, params: params)

        case .create(_ as CryptoAccountFormViewCreator):
            let params: [Analytics.ParameterKey: String] = [
                .accountName: trimmedAccountName,
                .accountColor: selectedColor.id.rawValue,
                .accountIcon: selectedIcon.id.rawValue,
                // In analytics this field is named "Derivation", but in the form we don't want to
                // expose any knowledge about derivation — as far as we're concerned, it's the account's ordinal number
                .accountDerivation: String(totalAccountsCount),
            ]

            Analytics.log(event: .accountSettingsButtonAddNewAccount, params: params)

        case .create:
            // The joint account flow has no events of its own specified yet
            break
        }
    }

    func onClose() {
        let currentSnapshot = StateSnapshot(name: trimmedAccountName, color: selectedColor, image: selectedIcon)

        if currentSnapshot != initialStateSnapshot {
            let message = switch flowType {
            case .edit:
                Localization.accountUnsavedDialogMessageEdit
            case .create:
                Localization.accountUnsavedDialogMessageCreate
            }

            alert = makeExitAlert(message: message)
        } else {
            close(.cancelled)
        }
    }

    // MARK: - Private

    private func editAccount(account: any BaseAccountModel) async throws(AccountEditError) {
        let currentSnapshot = StateSnapshot(name: trimmedAccountName, color: selectedColor, image: selectedIcon)

        try await account.edit { editor in
            if currentSnapshot.name != initialStateSnapshot.name {
                editor.setName(trimmedAccountName)
            }
            if currentSnapshot.color != initialStateSnapshot.color || currentSnapshot.image != initialStateSnapshot.image {
                editor.setIcon(accountIcon)
            }
        }
    }

    private func close(_ outcome: AccountFormOutcome) {
        activeTask?.cancel()
        coordinator?.closeAccountForm(outcome: outcome)
    }

    @MainActor
    private func handleFlowSuccess(_ output: AccountFormOperationResult) {
        switch (flowType, output) {
        case (.edit, _):
            Toast(view: SuccessToast(text: Localization.accountEditSuccessMessage))
                .present(layout: .top(padding: 24), type: .temporary(interval: 4))

        case (.create, .crypto):
            Toast(view: SuccessToast(text: Localization.accountCreateSuccessMessage))
                .present(layout: .top(padding: 24), type: .temporary(interval: 4))

            Analytics.log(.walletSettingsAccountCreated)

        case (.create, .joint):
            // No toasts for joint accounts creation
            break
        }

        close(.completed(output))
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
            .error: String(describing: error),
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
        case .invalidAccountName,
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
        guard case .create(let creator) = flowType else { return }

        creator.totalAccountsCountPublisher
            .receiveOnMain()
            .assign(to: &$totalAccountsCount)
    }

    private static func gridItemImageKind(from accountIconName: AccountModel.CompositeIcon.Name) -> GridItemImageKind {
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
                self?.close(.cancelled)
            }
        )
    }
}

// MARK: - Auxiliary types

extension AccountFormViewModel {
    enum FlowType {
        case edit(account: any CryptoAccountModel)
        case create(creator: any AccountFormViewCreator)
    }
}

extension AccountFormViewModel {
    struct StateSnapshot: Equatable {
        let name: String
        let color: GridItemColor<AccountModel.CompositeIcon.Color>
        let image: GridItemImage<AccountModel.CompositeIcon.Name>
    }
}

// MARK: - DescriptionResolver

private extension AccountFormViewModel {
    struct DescriptionResolver: AccountModelResolving {
        typealias Result = String?

        func resolve(accountModel: any CryptoAccountModel) -> Result {
            accountModel.descriptionString
        }

        /// TangemPay accounts don't have an editable description
        func resolve(accountModel: any TangemPayAccountModel) -> String? {
            nil
        }

        /// Polymarket accounts don't have an editable description
        func resolve(accountModel: any PolymarketAccountModel) -> String? {
            nil
        }
    }
}
