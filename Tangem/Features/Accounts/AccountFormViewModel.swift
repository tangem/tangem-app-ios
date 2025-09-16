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
import SwiftUI

final class AccountFormViewModel: ObservableObject, Identifiable {
    @Published var accountName: String
    @Published var selectedColor: GridItemColor
    @Published var selectedIcon: GridItemImage
    @Published var alert: AlertBinder?
    let maxNameLength = 20

    private var initialStateSnapshot: StateSnapshot = .initial
    private let flowType: FlowType
    private let closeAction: () -> Void
    private let accountModelsManager: AccountModelsManager
    private let accountIndex: Int

    let colors: [GridItemColor] = [
        Colors.Accounts.brightBlue,
        Colors.Accounts.cyan,
        Colors.Accounts.lavender,
        Colors.Accounts.purple,
        Colors.Accounts.magenta,
        Colors.Accounts.royalBlue,

        Colors.Accounts.deepPurple,
        Colors.Accounts.hotPink,
        Colors.Accounts.coralRed,
        Colors.Accounts.yellow,
        Colors.Accounts.mediumGreen,
        Colors.Accounts.darkGreen,
    ].map(GridItemColor.init)

    let images: [GridItemImage] = [
        Assets.Accounts.letter,
        Assets.Accounts.starAccounts,
        Assets.Accounts.user,
        Assets.Accounts.family,
        Assets.Accounts.walletAccounts,
        Assets.Accounts.money,

        Assets.Accounts.home,
        Assets.Accounts.safe,
        Assets.Accounts.beach,
        Assets.Accounts.airplane,
        Assets.Accounts.shirt,
        Assets.Accounts.shoppingBasket,

        Assets.Accounts.favorite,
        Assets.Accounts.bookmark,
        Assets.Accounts.startUp,
        Assets.Accounts.clock,
        Assets.Accounts.package,
        Assets.Accounts.gift,
    ].map {
        let kind: GridItemImageKind = $0 == Assets.Accounts.letter ? .letter(view: $0) : .image($0)
        return GridItemImage(kind)
    }

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
            selectedColor = GridItemColor(
                AccountModelMapper.mapAccountColor(account.icon.color)
            )

            let gridItemImageKind: GridItemImageKind = switch account.icon.nameMode {
            case .letter:
                .letter(view: Assets.Accounts.letter)

            case .named(let name):
                .image(AccountModelMapper.mapAccountImageName(name))
            }

            selectedIcon = GridItemImage(gridItemImageKind)

        case .create:
            let color = AccountModelMapper.mapAccountColor(
                AccountModelUtils.deriveIconColor(from: userWalletId)
            )
            selectedColor = GridItemColor(color)
            selectedIcon = GridItemImage(.letter(view: Assets.Accounts.letter))
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
            guard
                let accountIcon = AccountModelMapper.mapToAccountModelIcon(
                    selectedIcon,
                    color: selectedColor,
                    accountName: accountName
                )
            else {
                assertionFailure("Failed to map account icon. Should never happen")
                return
            }

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
        let color: GridItemColor
        let image: GridItemImage

        static let initial: Self = StateSnapshot(
            name: "",
            color: .init(.red),
            image: .init(.letter(view: Assets.tangemIcon))
        )
    }
}
