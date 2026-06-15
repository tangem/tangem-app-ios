//
//  TangemPayCloseCardSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemVisa

protocol TangemPayCloseCardSheetRoutable: AnyObject {
    func closeCloseCardSheet()
}

final class TangemPayCloseCardSheetViewModel: ObservableObject, FloatingSheetContentViewModel, TangemPayPopupViewModel {
    var icon: Image {
        isRedesigned
            ? DesignSystem.Icons.Error.regular28.image
            : Assets.Visa.kycDeclinedBrokenHeart.image
    }

    var iconStyle: TangemPayPopupIconStyle {
        .warning
    }

    var title: AttributedString {
        .init(Localization.tangemPayCloseCardPopupTitle)
    }

    var description: AttributedString {
        .init(Localization.tangemPayCloseCardPopupDescription)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.tangemPayCloseCardPopupPrimaryButtonTitle,
            style: .primary,
            size: .default,
            isLoading: isLoading,
            action: confirm
        )
    }

    var secondaryButton: MainButton.Settings? {
        MainButton.Settings(
            title: isRedesigned ? Localization.commonCancel : Localization.tangemPayCloseCardPopupSecondaryButtonTitle,
            style: .secondary,
            size: .default,
            action: dismiss
        )
    }

    private var isRedesigned: Bool {
        FeatureProvider.isAvailable(.tangemPaySpendRedesign)
    }

    @Published private(set) var isLoading: Bool = false

    private let userWalletId: UserWalletId
    private weak var coordinator: TangemPayCloseCardSheetRoutable?
    private let closeAction: () async throws -> Void
    private let onError: () -> Void

    init(
        userWalletId: UserWalletId,
        coordinator: TangemPayCloseCardSheetRoutable,
        closeAction: @escaping () async throws -> Void,
        onError: @escaping () -> Void
    ) {
        self.userWalletId = userWalletId
        self.coordinator = coordinator
        self.closeAction = closeAction
        self.onError = onError

        Analytics.log(.visaCloseCardConfirmationPopupOpened, contextParams: .userWallet(userWalletId))
    }

    func dismiss() {
        coordinator?.closeCloseCardSheet()
    }
}

// MARK: - Private

private extension TangemPayCloseCardSheetViewModel {
    func confirm() {
        guard !isLoading else { return }

        Analytics.log(.visaCloseCardConfirmed, contextParams: .userWallet(userWalletId))

        isLoading = true

        runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.closeAction()
                viewModel.dismiss()
            } catch {
                VisaLogger.error("Failed to close card", error: error)
                viewModel.isLoading = false
                viewModel.dismiss()
                viewModel.onError()
            }
        }
    }
}
