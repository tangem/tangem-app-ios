//
//  TangemPayReissueSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemVisa

protocol TangemPayReissueSheetRoutable: AnyObject {
    func closeReissueSheet()
    func openAddFundsFromReissueSheet()
}

final class TangemPayReissueSheetViewModel: ObservableObject, FloatingSheetContentViewModel, TangemPayPopupViewModel {
    var icon: Image {
        Image(systemName: "arrow.triangle.2.circlepath")
    }

    var title: AttributedString {
        .init(Localization.tangempayReissueCardTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayReissueCardDescription)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.tangempayCardDetailsReissueCard,
            style: .primary,
            size: .default,
            isLoading: isLoading,
            isDisabled: isInsufficientFunds,
            action: confirmReissue
        )
    }

    let feeText: String
    @Published private(set) var isLoading: Bool = false
    let isInsufficientFunds: Bool

    private let userWalletId: UserWalletId
    private let card: TangemPayCard
    private weak var coordinator: TangemPayReissueSheetRoutable?
    private let onError: () -> Void

    init(
        userWalletId: UserWalletId,
        card: TangemPayCard,
        feeText: String,
        isInsufficientFunds: Bool,
        coordinator: TangemPayReissueSheetRoutable,
        onError: @escaping () -> Void
    ) {
        self.userWalletId = userWalletId
        self.card = card
        self.feeText = feeText
        self.isInsufficientFunds = isInsufficientFunds
        self.coordinator = coordinator
        self.onError = onError

        Analytics.log(.visaReplaceCardConfirmationPopupOpened, contextParams: .userWallet(userWalletId))
    }

    func dismiss() {
        coordinator?.closeReissueSheet()
    }

    func openAddFunds() {
        coordinator?.openAddFundsFromReissueSheet()
    }
}

// MARK: - Private

private extension TangemPayReissueSheetViewModel {
    func confirmReissue() {
        guard !isLoading, !isInsufficientFunds else { return }

        Analytics.log(.visaReplaceCardConfirmed, contextParams: .userWallet(userWalletId))
        isLoading = true

        runTask(in: self) { viewModel in
            do {
                try await viewModel.card.reissue()
                viewModel.dismiss()
            } catch {
                VisaLogger.error("Failed to reissue card", error: error)
                viewModel.isLoading = false
                viewModel.dismiss()
                viewModel.onError()
            }
        }
    }
}
