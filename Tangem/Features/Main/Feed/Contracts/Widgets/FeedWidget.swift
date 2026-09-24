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
    case startEarning(LoadingResult<FeedEarnWidgetState, LoadError>, walletId: UserWalletId?)
    case tangemPay(walletId: UserWalletId)
    case referFriend(reward: LoadingResult<String, LoadError>, walletId: UserWalletId)
    case polymarket
    case collectibles

    var id: String { rawCaseValue }

    /// In-memory provenance of the rendered data, never an analytics parameter.
    var walletId: UserWalletId? {
        switch self {
        case .startEarning(_, let walletId): walletId
        case .tangemPay(let walletId), .referFriend(_, let walletId): walletId
        case .forYou, .addAccount, .polymarket, .collectibles: nil
        }
    }

    var span: Span {
        switch self {
        case .forYou, .addAccount: .compact
        case .startEarning, .tangemPay, .referFriend, .polymarket, .collectibles: .wide
        }
    }

    var loadingState: LoadingResult<Void, LoadError> {
        switch self {
        case .startEarning(let state, _): state.mapValue { _ in }
        case .referFriend(let reward, _): reward.mapValue { _ in }
        case .forYou, .addAccount, .tangemPay, .polymarket, .collectibles: .success(())
        }
    }
}
