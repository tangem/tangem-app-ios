//
//  TangemPayAddToAppPayGuideViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

protocol TangemPayAddToAppPayGuideRoutable: AnyObject {
    func closeAddToAppPayGuide()
}

final class TangemPayAddToAppPayGuideViewModel: ObservableObject, Identifiable {
    @Published private(set) var tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel

    private weak var coordinator: TangemPayAddToAppPayGuideRoutable?

    init(
        tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel,
        coordinator: TangemPayAddToAppPayGuideRoutable
    ) {
        self.tangemPayCardDetailsViewModel = tangemPayCardDetailsViewModel
        self.coordinator = coordinator
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
        coordinator?.closeAddToAppPayGuide()
    }
}

private extension TangemPayAddToAppPayGuideViewModel {
    enum Constants {
        static let appleWalletURLString = "wallet://"
    }
}
