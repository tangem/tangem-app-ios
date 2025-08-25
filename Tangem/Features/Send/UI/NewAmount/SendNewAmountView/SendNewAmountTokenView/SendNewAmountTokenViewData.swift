//
//  SendNewAmountTokenViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemUI

struct SendNewAmountTokenViewData: Identifiable {
    var id: Int { hashValue }

    let tokenIconInfo: TokenIconInfo
    let title: String
    let subtitle: String
    let detailsType: DetailsType?
    let action: (() -> Void)?

    init(
        tokenIconInfo: TokenIconInfo,
        title: String,
        subtitle: String,
        detailsType: DetailsType? = .none,
        action: (() -> Void)? = nil
    ) {
        self.tokenIconInfo = tokenIconInfo
        self.title = title
        self.subtitle = subtitle
        self.detailsType = detailsType
        self.action = action
    }
}

extension SendNewAmountTokenViewData: Hashable {
    static func == (lhs: SendNewAmountTokenViewData, rhs: SendNewAmountTokenViewData) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(tokenIconInfo)
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(detailsType)
    }
}

extension SendNewAmountTokenViewData {
    enum DetailsType: Hashable {
        case loading
        case max(action: () -> Void)
        case select(amount: String? = .none, individualAction: (() -> Void)? = .none)

        var individualAction: (() -> Void)? {
            switch self {
            case .loading, .max:
                return nil
            case .select(_, individualAction: let individualAction):
                return individualAction
            }
        }

        static func == (lhs: SendNewAmountTokenViewData.DetailsType, rhs: SendNewAmountTokenViewData.DetailsType) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .loading: hasher.combine("loading")
            case .max: hasher.combine("max")
            case .select(let amount, _): hasher.combine(amount)
            }
        }
    }
}
