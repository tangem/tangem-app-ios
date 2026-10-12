//
//  DeeplinkOverlayContext+Earn.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension DeeplinkOverlayContext {
    /// The Earn list, which two destinations lead to: the one that names it, and a Yield link that can't
    /// reach Yield mode.
    func makeEarnView(earnType: EarnFilterType?, networkId: String?) -> AnyView {
        AnyView(
            EarnDeeplinkContainerView(
                earnType: earnType,
                networkId: networkId,
                dismissAction: { dismiss() }
            )
        )
    }
}
