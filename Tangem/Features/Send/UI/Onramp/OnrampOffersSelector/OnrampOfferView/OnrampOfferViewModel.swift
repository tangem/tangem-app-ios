//
//  OnrampOfferViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import PassKit
import TangemExpress
import TangemAssets
import TangemFoundation
import SwiftUI

struct OnrampOfferViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    let title: Title
    let amount: Amount
    let provider: Provider
    let isAvailable: Bool
    let isNativePayment: Bool

    @IgnoredEquatable
    var buyAction: BuyAction

    init(
        title: Title,
        amount: Amount,
        provider: Provider,
        isAvailable: Bool,
        isNativePayment: Bool,
        buyAction: BuyAction
    ) {
        self.title = title
        self.amount = amount
        self.provider = provider
        self.isAvailable = isAvailable
        self.isNativePayment = isNativePayment
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

    enum BuyAction {
        case button(() -> Void)
        case nativeApplePay(
            request: PKPaymentRequest,
            onPhaseChange: (PayWithApplePayButtonPaymentAuthorizationPhase) -> Void
        )

        var isNativePayment: Bool {
            if case .nativeApplePay = self { return true }
            return false
        }
    }
}
