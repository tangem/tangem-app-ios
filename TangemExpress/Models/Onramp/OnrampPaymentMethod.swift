//
//  OnrampPaymentMethod.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampPaymentMethod: Hashable {
    public let id: String
    public let name: String
    public let image: URL
    public let imageLight: URL?
    public let imageDark: URL?

    public var type: MethodType {
        MethodType.from(id: id)
    }

    public init(id: String, name: String, image: URL, imageLight: URL? = nil, imageDark: URL? = nil) {
        self.id = id
        self.name = name
        self.image = image
        self.imageLight = imageLight
        self.imageDark = imageDark
    }

    public func imageURL(isDark: Bool) -> URL {
        let preferred = isDark ? imageDark : imageLight
        let alternative = isDark ? imageLight : imageDark
        return preferred ?? alternative ?? image
    }
}

public extension OnrampPaymentMethod {
    enum MethodType: Hashable {
        case applePay
        case card

        /// Google Pay doesn't support on iOS
        case googlePay

        case sepa
        case invoiceRevolutPay
        case moonpayBalance

        /// Generic for other not so important methods
        case other(id: String)

        public static func from(id: String) -> MethodType {
            switch id {
            case "apple-pay": .applePay
            case "card": .card
            case "google-pay": .googlePay
            case "sepa": .sepa
            case "invoice-revolut-pay": .invoiceRevolutPay
            case "moonpay-balance": .moonpayBalance
            default: .other(id: id)
            }
        }

        public var priority: Int {
            switch self {
            case .applePay: return 4
            case .card: return 3
            case .invoiceRevolutPay: return 2
            case .sepa: return 1
            case .moonpayBalance, .other: return 0
            case .googlePay: return -1
            }
        }

        public var processingTime: ProcessingTime {
            switch self {
            case .applePay, .googlePay, .invoiceRevolutPay, .moonpayBalance: .instant
            case .card: .minutes(min: 3, max: 5)
            case .sepa: .days(3)
            case .other: .days(5)
            }
        }

        public var speedRank: Int {
            switch self {
            case .applePay, .googlePay: 0
            case .invoiceRevolutPay: 1
            case .card: 2
            case .sepa: 3
            case .moonpayBalance, .other: 4
            }
        }
    }

    enum ProcessingTime: Hashable {
        case instant
        case minutes(min: Int, max: Int)
        case days(Int)
    }
}
