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

        /// Generic for other not so important methods
        case other(id: String)

        public static func from(id: String) -> MethodType {
            switch id {
            case "apple-pay": .applePay
            case "card": .card
            case "google-pay": .googlePay
            case "sepa": .sepa
            default: .other(id: id)
            }
        }

        public var priority: Int {
            switch self {
            case .applePay: return 2
            case .card: return 1
            case .sepa: return 0
            case .other: return 0
            case .googlePay: return -1
            }
        }
    }
}
