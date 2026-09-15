//
//  FeedWidget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemMacro

@RawCaseName
enum FeedWidget: Identifiable, Equatable {
    enum Span {
        case compact
        case wide
    }

    case forYou
    case addAccount
    case startEarning(FeedEarnWidgetState)
    case tangemPay
    case referFriend(reward: String)

    var id: String { rawCaseValue }

    var span: Span {
        switch self {
        case .forYou, .addAccount: .compact
        case .startEarning, .tangemPay, .referFriend: .wide
        }
    }
}
