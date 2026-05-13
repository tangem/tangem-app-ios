//
//  OnrampOfferViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemMacro
import PassKit
import SwiftUI
import TangemAssets
import TangemExpress
import TangemFoundation

struct OnrampOfferViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    let title: Title
    let amount: Amount
    let provider: Provider
    let isAvailable: Bool

    var isNativePayment: Bool { buyAction.isNativeApplePay }

    @IgnoredEquatable
    var buyAction: BuyAction

    init(
        title: Title,
        amount: Amount,
        provider: Provider,
        isAvailable: Bool,
        buyAction: BuyAction
    ) {
        self.title = title
        self.amount = amount
        self.provider = provider
        self.isAvailable = isAvailable
        self.buyAction = buyAction
    }
}

extension OnrampOfferViewModel {
    enum Title: Hashable {
        case text(String)
        case bestRate
        case great
        case fastest
    }

    struct Amount: Hashable {
        let formatted: String
        let badge: OnrampAmountBadge.Badge?
    }

    struct Provider: Hashable {
        let name: String
        let paymentType: OnrampPaymentMethod
        let timeFormatted: String
    }

    @CaseFlagable
    enum BuyAction {
        case button(() -> Void)
        case nativeApplePay(
            request: PKPaymentRequest,
            onPhaseChange: (PayWithApplePayButtonPaymentAuthorizationPhase) -> Void
        )
    }
}
