//
//  TokenWithAmountViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

struct TokenWithAmountViewData: Identifiable {
    var id: Int { hashValue }

    let tokenIconInfo: TokenIconInfo
    let title: String
    let subtitle: String
    let detailsType: DetailsType?
    let action: (() -> Void)?

    init(tokenIconInfo: TokenIconInfo, title: String, subtitle: String, detailsType: DetailsType? = .none, action: (() -> Void)? = nil) {
        self.tokenIconInfo = tokenIconInfo
        self.title = title
        self.subtitle = subtitle
        self.detailsType = detailsType
        self.action = action
    }
}

extension TokenWithAmountViewData: Hashable {
    static func == (lhs: TokenWithAmountViewData, rhs: TokenWithAmountViewData) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(tokenIconInfo)
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(detailsType)
        hasher.combine(action == nil)
    }
}

extension TokenWithAmountViewData {
    enum DetailsType: Hashable {
        case loading
        case max(action: () -> Void)
        case amount(String)
        case select(amount: String? = .none, action: () -> Void)

        static func == (lhs: TokenWithAmountViewData.DetailsType, rhs: TokenWithAmountViewData.DetailsType) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .loading: hasher.combine("loading")
            case .max: hasher.combine("max")
            case .amount(let string): hasher.combine(string)
            case .select(let amount, _): hasher.combine(amount)
            }
        }
    }
}
