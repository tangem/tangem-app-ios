//
//  _CommonRateAppService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]
final class _CommonRateAppService {
    @AppStorageCompat(StorageKeys.systemReviewPromptRequestDates)
    private var systemReviewPromptRequestDates: [Date] = []

    func requestRateAppIfAvailable(with request: RateAppRequest) {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - Auxiliary types

extension _CommonRateAppService {
    struct RateAppRequest {
        let isLocked: Bool
        let totalBalances: [TotalBalanceProvider.TotalBalance]
        let displayedNotifications: [NotificationViewInput]
    }
}

private extension _CommonRateAppService {
    enum StorageKeys: String, RawRepresentable {
        case systemReviewPromptRequestDates = "system_review_prompt_request_dates"
    }
}

// MARK: - Dependency injection

// [REDACTED_TODO_COMMENT]
private struct RateAppServiceKey: InjectionKey {
    static var currentValue: _CommonRateAppService = .init()
}

// [REDACTED_TODO_COMMENT]
extension InjectedValues {
    var _rateAppService: _CommonRateAppService {
        get { Self[RateAppServiceKey.self] }
        set { Self[RateAppServiceKey.self] = newValue }
    }
}
