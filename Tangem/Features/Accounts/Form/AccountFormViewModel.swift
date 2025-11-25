//
//  AccountFormViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import Foundation
import TangemLocalization
import TangemUIUtils
import TangemAccounts
import TangemFoundation
import CombineExt
import Combine
import SwiftUI

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

    // MARK: - Dependencies

    private let initialStateSnapshot: StateSnapshot
    private let flowType: FlowType
    private let closeAction: () -> Void
    private let accountModelsManager: AccountModelsManager

    private var bag = Set<AnyCancellable>()

    init(
        accountModelsManager: AccountModelsManager,
        flowType: FlowType,
        closeAction: @escaping () -> Void
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

        // [REDACTED_TODO_COMMENT]
        description = if let cryptoAccount = flowType.account as? any CryptoAccountModel {
            cryptoAccount.descriptionString
        } else {
            nil
        }

        initialStateSnapshot = StateSnapshot(name: accountName, color: selectedColor, image: selectedIcon)

        bind()
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
        Task {
            isLoading = true
            defer { isLoading = false }

            let accountIcon = AccountModel.Icon(name: selectedIcon.id, color: selectedColor.id)

            switch flowType {
            case .edit(let account):
                account.setName(accountName)
                account.setIcon(accountIcon)
                close()

            case .create:
                do {
                    try await accountModelsManager.addCryptoAccount(name: accountName, icon: accountIcon)
                    close()
                } catch {
                    alert = makeUnableToCreateAccountAlert()
                }
            }
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
            return
        }

        close()
    }

    // MARK: - Private

    private func close() {
        closeAction()
    }

    private func bind() {
        accountModelsManager.totalAccountsCountPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, amount in
                if case .create = viewModel.flowType {
                    Localization.accountFormAccountIndex(amount)
                } else {
                    nil
                }
            }
            .assign(to: \.description, on: self, ownership: .weak)
            .store(in: &bag)
    }

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

    // MARK: - Alerts

    private func makeExitAlert(message: String) -> AlertBinder {
        AlertBuilder.makeExitAlert(
            title: Localization.accountUnsavedDialogTitle,
            message: message,
            keepEditingButtonText: Localization.accountUnsavedDialogActionFirst,
            discardButtonText: Localization.accountUnsavedDialogActionSecond,
            discardAction: close
        )
    }

    private func makeUnableToCreateAccountAlert() -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.commonSomethingWentWrong,
            message: Localization.accountCouldNotCreate,
            primaryButton: .default(Text(Localization.commonOk))
        )
    }
}

extension AccountFormViewModel {
    enum FlowType {
        case edit(account: any BaseAccountModel)
        case create(CreatedAccountType)

        var account: (any BaseAccountModel)? {
            switch self {
            case .create: nil
            case .edit(let account): account
            }
        }
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
