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
    let subtitle: SubtitleType
    let detailsType: DetailsType?
    let action: (() -> Void)?

    init(
        tokenIconInfo: TokenIconInfo,
        title: String,
        subtitle: SubtitleType,
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
    enum SubtitleType: Hashable {
        case balance(state: LoadableTokenBalanceView.State)
        case receive(state: LoadableTextView.State)
    }

    enum DetailsType: Hashable {
        case max(action: () -> Void)
        case select(individualAction: (() -> Void)? = .none)

        var individualAction: (() -> Void)? {
            switch self {
            case .max:
                return nil
            case .select(individualAction: let individualAction):
                return individualAction
            }
        }

        static func == (lhs: SendNewAmountTokenViewData.DetailsType, rhs: SendNewAmountTokenViewData.DetailsType) -> Bool {
            lhs.hashValue == rhs.hashValue
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .max: hasher.combine("max")
            case .select: hasher.combine("select")
            }
        }
    }
}
