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
    private let visaAccount: VisaAccount
    private let closeOfferScreen: @MainActor @Sendable () -> Void

    init(
        visaAccount: VisaAccount,
        closeOfferScreen: @escaping @MainActor @Sendable () -> Void
    ) {
        self.visaAccount = visaAccount
        self.closeOfferScreen = closeOfferScreen
    }

    func getCard() {
        #if ALPHA || BETA || DEBUG
        isLoading = true
        Task {
            do {
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
