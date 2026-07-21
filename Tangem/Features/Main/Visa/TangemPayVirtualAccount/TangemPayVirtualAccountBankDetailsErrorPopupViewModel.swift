//
//  TangemPayVirtualAccountBankDetailsErrorPopupViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemVisa

@MainActor
final class TangemPayVirtualAccountBankDetailsErrorPopupViewModel: TangemPayPopupViewModel {
    @Published private(set) var isLoading = false

    var icon: Image {
        DesignSystem.Icons.Error.regular28.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .warning
    }

    var title: AttributedString {
        .init(Localization.tangempayVaBankingDetailsErrorTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayVaBankingDetailsErrorDescription)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.commonRetry,
            style: .primary,
            size: .default,
            isLoading: isLoading,
            action: retry
        )
    }

    var secondaryButton: MainButton.Settings? {
        MainButton.Settings(
            title: Localization.commonContactSupport,
            style: .secondary,
            size: .default,
            action: contactSupport
        )
    }

    private let tangemPayAccount: TangemPayAccount
    private let productInstanceId: String
    private weak var coordinator: TangemPayVirtualAccountBankDetailsErrorPopupRoutable?

    init(
        tangemPayAccount: TangemPayAccount,
        productInstanceId: String,
        coordinator: TangemPayVirtualAccountBankDetailsErrorPopupRoutable
    ) {
        self.tangemPayAccount = tangemPayAccount
        self.productInstanceId = productInstanceId
        self.coordinator = coordinator
    }

    func dismiss() {
        coordinator?.closeVirtualAccountSheet()
    }

    private func contactSupport() {
        coordinator?.virtualAccountBankDetailsErrorPopupDidRequestSupport()
    }

    private func retry() {
        guard !isLoading else { return }
        isLoading = true

        runTask(in: self) { @MainActor viewModel in
            defer { viewModel.isLoading = false }

            do {
                let credentials = try await viewModel.tangemPayAccount.loadBankCredentials(productInstanceId: viewModel.productInstanceId)
                viewModel.coordinator?.virtualAccountDidLoadBankCredentials(credentials)
            } catch {
                VisaLogger.error("Failed to load virtual account bank credentials", error: error)
            }
        }
    }
}
