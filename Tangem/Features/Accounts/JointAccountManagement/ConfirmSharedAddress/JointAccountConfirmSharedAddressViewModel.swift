//
//  JointAccountConfirmSharedAddressViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemUI

final class JointAccountConfirmSharedAddressViewModel: ObservableObject {
    let address: String
    let signingActionButtonType: SigningActionButtonViewType

    private let copyHelper = JointAccountCopyHelper()
    private weak var coordinator: JointAccountConfirmSharedAddressRoutable?

    init(
        address: String,
        signingActionButtonType: SigningActionButtonViewType,
        coordinator: JointAccountConfirmSharedAddressRoutable?
    ) {
        self.address = address
        self.signingActionButtonType = signingActionButtonType
        self.coordinator = coordinator
    }

    func onAddressTap() {
        copyHelper.copy(address, toast: Localization.commonValueCopied)
    }

    func onShareAddressTap() {
        coordinator?.shareSharedAddress(address)
    }

    func onAddressMismatchTap() {
        coordinator?.openSharedAddressMismatch()
    }

    func onConfirmTap() {
        coordinator?.confirmSharedAddress()
    }
}
