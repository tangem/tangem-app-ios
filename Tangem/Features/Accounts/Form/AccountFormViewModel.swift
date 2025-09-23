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

    let colors: [GridItemColor] = AccountModel.Icon.Color
        .allCases
        .map { iconColor in
            let color = AccountModelUtils.UI.iconColor(from: iconColor)

            return GridItemColor(color)
        }

    let images: [GridItemImage] = AccountModel.Icon.Name
        .allCases
        .map { iconName in
            let image = AccountModelUtils.UI.iconAsset(from: iconName)
            let kind: GridItemImageKind = iconName == .letter ? .letter(image) : .image(image)

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
