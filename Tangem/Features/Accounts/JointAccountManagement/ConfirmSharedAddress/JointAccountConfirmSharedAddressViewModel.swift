//
//  JointAccountConfirmSharedAddressViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
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

        let status: JointAccountStatus

        do throws(AccountEditError) {
            status = try await jointAccount.confirm(safeAddress: address)
        } catch .unknownError(let underlying) where underlying.isCancellationError {
            return
        } catch {
            alert = AccountEditErrorAlertBuilder.makeAlert(for: error)
            return
        }

        if status.isActive {
            let snackbar = TangemSnackbar(title: Localization.jointAccountActivatedSnackbar)
                .icon(DesignSystem.Icons.Success.regular20)
                .iconColor(DesignSystem.Color.iconAccentBlue)
            Toast(view: snackbar).present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
        }

        coordinator?.didConfirmSharedAddress()
    }
}

// MARK: - Constants

private extension JointAccountConfirmSharedAddressViewModel {
    enum Constants {
        static let toastTopPadding: CGFloat = 14
    }
}
