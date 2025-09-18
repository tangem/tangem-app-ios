//
//  OnrampPaymentMethod.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPaymentMethod: Hashable {
    public let id: String
    public let name: String
    public let image: URL

    public var type: MethodType {
        MethodType.from(id: id)
    }

    public init(id: String, name: String, image: URL) {
        self.id = id
        self.name = name
        self.image = image
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

        /// Generic for other not so important methods
        case other(id: String)

        public static func from(id: String) -> MethodType {
            switch id {
            case "apple-pay": .applePay
            case "card": .card
            case "google-pay": .googlePay
            case "sepa": .sepa
            case "invoice-revolut-pay": .invoiceRevolutPay
            default: .other(id: id)
            }
        }

        public var priority: Int {
            switch self {
            case .applePay: return 2
            case .card: return 1
            case .sepa, .invoiceRevolutPay, .other: return 0
            case .googlePay: return -1
            }
        }

        public var processingTime: ProcessingTime {
            switch self {
            case .applePay, .googlePay: .instant
            case .invoiceRevolutPay: .instant
            case .card: .minutes(min: 3, max: 5)
            case .sepa: .days(3)
            case .other: .days(5)
            }
        }
    }

    enum ProcessingTime: Hashable, Comparable {
        case instant
        case minutes(min: Int, max: Int)
        case days(Int)
    }
}
