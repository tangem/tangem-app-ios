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

final class AccountFormViewModel: ObservableObject {
    @Published var accountName: String
    @Published var selectedColor: GridItemColor
    @Published var selectedIcon: GridItemImage
    @Published var alert: AlertBinder?

    private var initialStateSnapshot: StateSnapshot = .initial
    private let flowType: FlowType

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
        let kind: GridItemImageKind = $0 == Assets.Accounts.letter ? .letter($0) : .image($0)
        return GridItemImage(kind)
    }

    /// NOTE: This hard-code is here until real data is ready
    /// Until then, I don't know for sure which models will be passed here
    init(flowType: FlowType) {
        accountName = ""
        selectedColor = colors.randomElement()!
        selectedIcon = images.randomElement()!
        self.flowType = flowType

        initialStateSnapshot = StateSnapshot(
            name: accountName,
            color: selectedColor,
            image: selectedIcon
        )
    }

    // MARK: - ViewData

    var headerType: AccountFormHeaderType {
        switch selectedIcon.kind {
        case .image(let imageType):
            return .image(imageType.image)

        case .letter:
            if let firstLetter = accountName.first {
                return .letter(String(firstLetter))
            }

            return .image(
                Assets.tangemIcon.image,
                config: AccountFormHeaderType.ImageConfig(opacity: 0.4)
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
        // [REDACTED_TODO_COMMENT]
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

    /// Dont know what this text willbe, but it is present in figma
    var bottomText: String {
        "Placeholder"
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

    func onMainButtonTap() {}

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

    private func close() {}

    private func makeExitAlert(message: String) -> AlertBinder {
        AlertBuilder.makeExitAlert(
            title: Localization.accountUnsavedDialogTitle,
            message: message,
            keepEditingButtonText: Localization.accountUnsavedDialogActionFirst,
            discardButtonText: Localization.accountUnsavedDialogActionSecond,
            discardAction: close
        )
    }
}

extension AccountFormViewModel {
    enum FlowType {
        case edit
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
            image: .init(.letter(Assets.tangemIcon))
        )
    }
}
