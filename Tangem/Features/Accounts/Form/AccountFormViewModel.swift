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
    @Published private var accountIndex: Int

    // MARK: - Static state

    let maxNameLength = 20
    let colors: [GridItemColor] = AccountModel.Icon.Color
        .allCases
        .map { iconColor in
            let color = AccountModelUtils.UI.iconColor(from: iconColor)

            return GridItemColor(id: iconColor, color: color)
        }

    let images: [GridItemImage] = AccountModel.Icon.Name
        .allCases
        .map { iconName in
            let image = AccountModelUtils.UI.iconAsset(from: iconName)
            let kind: GridItemImageKind = iconName == .letter ? .letter(visualImageRepresentation: image) : .image(image)

            return GridItemImage(id: iconName, kind: kind)
        }

    // MARK: - Dependencies

    private var initialStateSnapshot: StateSnapshot = .initial
    private let flowType: FlowType
    private let closeAction: () -> Void
    private let accountModelsManager: AccountModelsManager

    private var bag = Set<AnyCancellable>()

    init(
        userWalletId: UserWalletId,
        accountIndex: Int,
        accountModelsManager: AccountModelsManager,
        flowType: FlowType,
        closeAction: @escaping () -> Void
    ) {
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
            let randomAccountColor = AccountModel.Icon.Color.allCases.randomElement() ?? .azure
            let color = AccountModelUtils.UI.iconColor(from: randomAccountColor)
            selectedColor = GridItemColor(id: randomAccountColor, color: color)
            selectedIcon = GridItemImage(
                id: .letter,
                kind: .letter(visualImageRepresentation: Assets.Accounts.letter)
            )
            accountName = ""
        }

        self.flowType = flowType
        self.closeAction = closeAction
        self.accountModelsManager = accountModelsManager
        self.accountIndex = accountIndex

        initialStateSnapshot = StateSnapshot(
            name: accountName,
            color: selectedColor,
            image: selectedIcon
        )

        bind()
    }

    // MARK: - ViewData

    var nameMode: AccountIconView.NameMode {
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

    var bottomText: String {
        Localization.accountFormAccountIndex(accountIndex)
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

    // MARK: - Private methods

    private func close() {
        closeAction()
    }

    private func bind() {
        accountModelsManager.accountModelsPublisher
            .map { $0.count + 1 }
            .assign(to: \.accountIndex, on: self, ownership: .weak)
            .store(in: &bag)
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

    // [REDACTED_TODO_COMMENT]
    private func makeUnableToCreateAccountAlert() -> AlertBinder {
        AlertBuilder.makeAlert(
            title: "Something went wrong",
            message: "We couldn’t create account. Please try again later.",
            primaryButton: .default(Text(Localization.commonOk))
        )
    }
}

extension AccountFormViewModel {
    enum FlowType {
        case edit(account: any BaseAccountModel)
        case create
    }
}

extension AccountFormViewModel {
    struct StateSnapshot: Equatable {
        let name: String
        let color: GridItemColor<AccountModel.Icon.Color>
        let image: GridItemImage<AccountModel.Icon.Name>

        static let initial: Self = StateSnapshot(
            name: "",
            color: .init(id: .azure, color: Colors.Accounts.azureBlue),
            image: .init(id: .letter, kind: .letter(visualImageRepresentation: Assets.tangemIcon))
        )
    }
}
