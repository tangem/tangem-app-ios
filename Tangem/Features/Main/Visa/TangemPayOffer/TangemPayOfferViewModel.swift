//
//  TangemPayOfferViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class TangemPayOfferViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    private let tangemPayAuthorizer: TangemPayAuthorizer
    private let closeOfferScreen: @MainActor @Sendable () -> Void

    init(
        tangemPayAuthorizer: TangemPayAuthorizer,
        closeOfferScreen: @escaping @MainActor @Sendable () -> Void
    ) {
        self.tangemPayAuthorizer = tangemPayAuthorizer
        self.closeOfferScreen = closeOfferScreen
    }

    func getCard() {
        #if ALPHA || BETA || DEBUG
        isLoading = true
        Task {
            do {
                let tokens = try await tangemPayAuthorizer.authorizeWithCustomerWallet()
                let visaAccount = VisaAccount(authorizer: tangemPayAuthorizer, tokens: tokens)
                try await visaAccount.launchKYC()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await closeOfferScreen()
            }
        }
        #endif // ALPHA || BETA || DEBUG
    }
}
