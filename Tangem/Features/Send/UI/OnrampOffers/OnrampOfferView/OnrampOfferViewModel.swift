//
//  OnrampOfferViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemAssets
import TangemFoundation

struct OnrampOfferViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    let title: Title
    let amount: Amount
    let provider: Provider

    @IgnoredEquatable
    var buyButtonAction: () -> Void

    init(title: Title, amount: Amount, provider: Provider, buyButtonAction: @escaping () -> Void) {
        self.title = title
        self.amount = amount
        self.provider = provider
        self.buyButtonAction = buyButtonAction
    }
}

extension OnrampOfferViewModel {
    enum Title: Hashable {
        case text(String)
        case bestRate
        case fastest
    }

    struct Amount: Hashable {
        let formatted: String
        let badge: Badge?

        enum Badge: Hashable {
            case best
            case loss(percent: String, signType: ChangeSignType)
        }
    }

    struct Provider: Hashable {
        let name: String
        let paymentType: OnrampPaymentMethod
        let timeFormatted: String

        var paymentTypeMethodIcon: ImageType {
            switch paymentType.type {
            case .applePay: Assets.Express.PaymentMethods.applePay
            case .sepa: Assets.Express.PaymentMethods.sepa
            case .invoiceRevolutPay: Assets.Express.PaymentMethods.revolutPay
            case .card: Assets.Express.PaymentMethods.card
            case .googlePay, .other: Assets.Express.PaymentMethods.card
            }
        }
    }
}
