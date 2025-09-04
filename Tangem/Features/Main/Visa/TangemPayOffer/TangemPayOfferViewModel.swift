//
//  TangemPayOfferViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemPayOfferViewModel {
    let visaAccount: VisaAccount

    func getCard() {
        #if ALPHA || BETA || DEBUG
        Task {
            do {
                try await visaAccount.launchKYC()
            } catch {
                // [REDACTED_TODO_COMMENT]
            }
        }
        #endif // ALPHA || BETA || DEBUG
    }
}
