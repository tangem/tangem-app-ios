//
//  TangemPayOnboardingHostingController.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class TangemPayOnboardingHostingController: UIHostingController<TangemPayOnboardingView> {
    /// Overriding default dismiss method isn't a solution
    /// because of TangemSDK not dismissing itself but enforce dismiss on its presentingViewController
    func customDismiss() {
        if let presentedViewController {
            presentedViewController.dismiss(animated: true) { [weak self] in
                self?.dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }
}
