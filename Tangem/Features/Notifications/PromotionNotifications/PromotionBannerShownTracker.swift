//
//  PromotionBannerShownTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Tracks which promotion banners have already emitted a `Banner Shown` analytics event
/// during the current app session. Lives as a singleton so that manager/view-model
/// re-instantiation (e.g. after page rebuild on wallet unlock) does not re-fire the event
/// for the same `displayId`.
protocol PromotionBannerShownTracker {
    func hasBeenShown(displayId: Int) -> Bool
    func markAsShown(displayId: Int)
}

final class CommonPromotionBannerShownTracker: PromotionBannerShownTracker {
    private let lock = NSLock()
    private var shownDisplayIds: Set<Int> = []

    func hasBeenShown(displayId: Int) -> Bool {
        lock.withLock { shownDisplayIds.contains(displayId) }
    }

    func markAsShown(displayId: Int) {
        _ = lock.withLock { shownDisplayIds.insert(displayId) }
    }
}

private struct PromotionBannerShownTrackerKey: InjectionKey {
    static var currentValue: PromotionBannerShownTracker = CommonPromotionBannerShownTracker()
}

extension InjectedValues {
    var promotionBannerShownTracker: PromotionBannerShownTracker {
        get { Self[PromotionBannerShownTrackerKey.self] }
        set { Self[PromotionBannerShownTrackerKey.self] = newValue }
    }
}
