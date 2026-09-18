//
//  FeedWidget.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemMacro

@RawCaseName
enum FeedWidget: Identifiable, Equatable {
    enum Span {
        case compact
        case wide
    }

    struct LoadError: Error, Equatable {}

    case forYou
    case addAccount
    case startEarning(LoadingResult<FeedEarnWidgetState, LoadError>)
    case tangemPay
    case referFriend(reward: LoadingResult<String, LoadError>)

    var id: String { rawCaseValue }

    var span: Span {
        switch self {
        case .forYou, .addAccount: .compact
        case .startEarning, .tangemPay, .referFriend: .wide
        }
    }

    var loadingState: LoadingResult<Void, LoadError> {
        switch self {
        case .startEarning(let state): state.mapValue { _ in }
        case .referFriend(let reward): reward.mapValue { _ in }
        case .forYou, .addAccount, .tangemPay: .success(())
        }
    }
}
