//
//  TangemPayAddToAppPayGuideViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

final class TangemPayAddToAppPayGuideViewModel: ObservableObject, Identifiable {
    @Published private(set) var tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel

    init(tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel) {
        self.tangemPayCardDetailsViewModel = tangemPayCardDetailsViewModel
    }

    func openAppleWalletApp() {
        if let url = URL(string: Constants.appleWalletURLString) {
            UIApplication.shared.open(url)
        }
    }

    func onAppear() {
        tangemPayCardDetailsViewModel.setVisibility(true)
    }

    func onDismiss() {
        AppSettings.shared.tangemPayHasDismissedAddToApplePayGuide = true
    }
}

private extension TangemPayAddToAppPayGuideViewModel {
    enum Constants {
        static let appleWalletURLString = "wallet://"
    }
}
