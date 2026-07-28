//
//  TangemPayVirtualAccountInfoSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemUIUtils
import TangemFoundation
import TangemLocalization
import TangemVisa

@MainActor
final class TangemPayVirtualAccountInfoSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var isLoading = false
    @Published var alert: AlertBinder?

    var agreementText: AttributedString {
        let terms = Localization.commonTermsOfUse
        let privacy = Localization.commonPrivacyPolicy

        var attributedString = AttributedString(Localization.tangempayBankTransferLegal(terms, privacy))

        if let range = attributedString.range(of: terms) {
            attributedString[range].link = AppConstants.tangemPayVirtualAccountTermsURL
        }

        if let range = attributedString.range(of: privacy) {
            attributedString[range].link = AppConstants.tangemPayPrivacyPolicyURL
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

        switch tangemPayAccount.virtualAccountEntry {
        case .active(let productInstanceId):
            loadBankCredentials(productInstanceId: productInstanceId)
        case .none, .preparing:
            createVirtualAccountOrder()
        }
    }

    private func loadBankCredentials(productInstanceId: String) {
        runTask(in: self) { @MainActor viewModel in
            defer { viewModel.isLoading = false }

            do {
                let credentials = try await viewModel.tangemPayAccount.loadBankCredentials(productInstanceId: productInstanceId)
                viewModel.coordinator?.virtualAccountDidLoadBankCredentials(credentials)
            } catch {
                VisaLogger.error("Failed to load virtual account bank credentials", error: error)
                viewModel.coordinator?.virtualAccountInfoSheetDidFailToLoadBankCredentials(productInstanceId: productInstanceId)
            }
        }
    }

    private func createVirtualAccountOrder() {
        runTask(in: self) { @MainActor viewModel in
            do {
                try await viewModel.tangemPayAccount.createVirtualAccount()
                viewModel.isLoading = false
                viewModel.coordinator?.virtualAccountInfoSheetDidCreateOrder()
            } catch {
                viewModel.isLoading = false
                // [REDACTED_TODO_COMMENT]
                viewModel.alert = AlertBinder(
                    title: Localization.commonSomethingWentWrong,
                    message: Localization.commonTryAgainLater
                )
            }
        }
    }

    func close() {
        coordinator?.closeVirtualAccountSheet()
    }

    func openURL(_ url: URL) {
        coordinator?.openVirtualAccountURL(url)
    }
}
