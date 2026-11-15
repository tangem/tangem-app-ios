//
//  JointAccountConfirmSharedAddressViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemUI
import struct TangemUIUtils.AlertBinder

final class JointAccountConfirmSharedAddressViewModel: ObservableObject {
    @Published private(set) var isConfirming = false
    @Published var alert: AlertBinder?

    let address: String
    let signingActionButtonType: SigningActionButtonViewType

    private let jointAccount: any JointAccountModel
    private let copyHelper = JointAccountCopyHelper()
    private weak var coordinator: JointAccountConfirmSharedAddressRoutable?

    init(
        address: String,
        jointAccount: any JointAccountModel,
        signingActionButtonType: SigningActionButtonViewType,
        coordinator: JointAccountConfirmSharedAddressRoutable?
    ) {
        self.address = address
        self.jointAccount = jointAccount
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
        guard !isConfirming else {
            return
        }

        isConfirming = true

        runTask(in: self) { viewModel in
            await viewModel.confirm()
        }
    }
}

// MARK: - Private

private extension JointAccountConfirmSharedAddressViewModel {
    @MainActor
    func confirm() async {
        defer { isConfirming = false }

        do throws(AccountEditError) {
            try await jointAccount.confirm(safeAddress: address)
        } catch .unknownError(let underlying) where underlying.isCancellationError {
            return
        } catch {
            alert = AccountEditErrorAlertBuilder.makeAlert(for: error)
            return
        }

        coordinator?.didConfirmSharedAddress()
    }
}
