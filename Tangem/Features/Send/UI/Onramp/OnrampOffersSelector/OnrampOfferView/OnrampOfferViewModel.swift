//
//  OnrampOfferViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemMacro
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
    let legalNotice: LegalNotice?
    let linkedBanner: LinkedMarketingBannerViewModel?

    var isNativePayment: Bool { buyAction.isNativeApplePay }

    @IgnoredEquatable
    var buyAction: BuyAction

    init(
        title: Title,
        amount: Amount,
        provider: Provider,
        isAvailable: Bool,
        buyAction: BuyAction,
        legalNotice: LegalNotice? = nil,
        linkedBanner: LinkedMarketingBannerViewModel? = nil
    ) {
        self.title = title
        self.amount = amount
        self.provider = provider
        self.isAvailable = isAvailable
        self.buyAction = buyAction
        self.legalNotice = legalNotice
        self.linkedBanner = linkedBanner
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

        @IgnoredEquatable
        var infoAction: (() -> Void)?

        init(
            formatted: String,
            badge: OnrampAmountBadge.Badge?,
            infoAction: (() -> Void)? = nil
        ) {
            self.formatted = formatted
            self.badge = badge
            self.infoAction = infoAction
        }
    }

    struct Provider: Hashable {
        let name: String
        let paymentType: OnrampPaymentMethod
        let timeFormatted: String
    }

    struct LegalNotice: Hashable {
        let providerName: String
        let termsOfUse: URL?
        let privacyPolicy: URL?
    }

    @CaseFlagable
    enum BuyAction {
        case button(() -> Void)
        case nativeApplePay(onTap: @MainActor () -> Void)
    }
}
