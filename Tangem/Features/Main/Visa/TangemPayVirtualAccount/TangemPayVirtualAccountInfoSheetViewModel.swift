//
//  TangemPayVirtualAccountInfoSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemUIUtils
import TangemLocalization

@MainActor
final class TangemPayVirtualAccountInfoSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var isLoading = false
    @Published var alert: AlertBinder?

    var agreementText: AttributedString {
        let terms = Localization.commonTermsOfUse
        let privacy = Localization.commonPrivacyPolicy

        var attributedString = AttributedString(Localization.tangempayBankTransferLegal(terms, privacy))

        if let range = attributedString.range(of: terms) {
            attributedString[range].link = AppConstants.tosURL
        }

        if let range = attributedString.range(of: privacy) {
            // [REDACTED_TODO_COMMENT]
            attributedString[range].link = AppConstants.tosURL
        }

        return attributedString
    }

    private let tangemPayAccount: TangemPayAccount
    private weak var coordinator: TangemPayVirtualAccountInfoSheetRoutable?

    init(tangemPayAccount: TangemPayAccount, coordinator: TangemPayVirtualAccountInfoSheetRoutable) {
        self.tangemPayAccount = tangemPayAccount
        self.coordinator = coordinator
    }

    func showDetails() {
        guard !isLoading else { return }
        isLoading = true

        Task { [weak self] in
            guard let self else { return }
            do {
                try await tangemPayAccount.createVirtualAccount()
                isLoading = false
                coordinator?.virtualAccountInfoSheetDidCreateOrder()
            } catch {
                isLoading = false
                // [REDACTED_TODO_COMMENT]
                alert = AlertBinder(
                    title: Localization.commonSomethingWentWrong,
                    message: Localization.commonTryAgainLater
                )
            }
        }
    }

    func close() {
        coordinator?.closeVirtualAccountInfoSheet()
    }

    func openURL(_ url: URL) {
        coordinator?.openVirtualAccountURL(url)
    }
}
