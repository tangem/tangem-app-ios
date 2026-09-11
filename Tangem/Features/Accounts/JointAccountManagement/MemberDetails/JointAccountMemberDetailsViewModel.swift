//
//  JointAccountMemberDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit
import TangemAssets
import TangemLocalization
import TangemUI

final class JointAccountMemberDetailsViewModel: FloatingSheetContentViewModel {
    let name: String
    let address: String
    let accentColor: Color
    let monogram: String

    private weak var coordinator: JointAccountMemberDetailsRoutable?

    init(
        name: String,
        address: String,
        accentColor: Color,
        coordinator: JointAccountMemberDetailsRoutable?
    ) {
        self.name = name
        self.address = address
        self.accentColor = accentColor
        self.coordinator = coordinator

        monogram = name.prefix(1).uppercased()
    }

    func onCopyTap() {
        UIPasteboard.general.string = address

        let snackbar = TangemSnackbar(title: Localization.addressBookAddressCopied)
            .icon(DesignSystem.Icons.Success.regular20)
            .iconColor(DesignSystem.Color.iconAccentBlue)
        Toast(view: snackbar).present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
    }

    func onCloseTap() {
        coordinator?.closeMemberDetails()
    }
}

// MARK: - Constants

private extension JointAccountMemberDetailsViewModel {
    enum Constants {
        static let toastTopPadding: CGFloat = 8
    }
}
