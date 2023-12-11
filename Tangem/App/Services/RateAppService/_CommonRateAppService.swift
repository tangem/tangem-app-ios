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

    @AppStorageCompat(StorageKeys.lastRequestedReviewDate)
    private var lastRequestedReviewDate: Date = .distantPast

    @AppStorageCompat(StorageKeys.lastRequestedReviewLaunchCount)
    private var lastRequestedReviewLaunchCount: Int = 0

    @AppStorageCompat(StorageKeys.userDismissedLastRequestedReview)
    private var userDismissedLastRequestedReview: Bool = false

    private var currentLaunchCount: Int { AppSettings.shared.numberOfLaunches }

    private var requiredNumberOfLaunches: Int {
        return userDismissedLastRequestedReview
            ? Constants.dismissedReviewRequestNumberOfLaunchesInterval
            : Constants.normalReviewRequestNumberOfLaunchesInterval
    }

    private lazy var calendar = Calendar(identifier: .gregorian)

    init() {
        trimStorageIfNeeded()
    }

    func requestRateAppIfAvailable(with request: RateAppRequest) {
        if request.isSelectedPageLocked {
            return
        }

        if request.isSelectedPageFailedToLoadTotalBalance {
            return
        }

        if request.selectedPageDisplayedNotifications.contains(where: { Constants.forbiddenSeverityLevels.contains($0.severity) }) {
            return
        }

        guard request.totalBalances.contains(where: { ($0.balance ?? .zero) > .zero }) else {
            return
        }

        guard lastRequestedReviewDate.timeIntervalSinceNow < -Constants.reviewRequestTimeInterval else {
            return
        }

        guard currentLaunchCount - lastRequestedReviewLaunchCount >= requiredNumberOfLaunches else {
            return
        }

        guard let referenceDate = makeSystemReviewPromptReferenceDate() else {
            return
        }

        let systemReviewPromptRequestDatesWithinLastYear = systemReviewPromptRequestDates.filter { $0 >= referenceDate }

        guard systemReviewPromptRequestDatesWithinLastYear.count < Constants.systemReviewPromptMaxCountPerYear else {
            return
        }

        lastRequestedReviewDate = Date()
        lastRequestedReviewLaunchCount = currentLaunchCount
        userDismissedLastRequestedReview = false
    }

    private func makeSystemReviewPromptReferenceDate() -> Date? {
        return calendar.date(byAdding: .year, value: -Constants.systemReviewPromptTimeWindowSize, to: Date())
    }

    private func trimStorageIfNeeded() {
        let storageMaxSize = Constants.systemReviewPromptRequestDatesMaxSize
        if systemReviewPromptRequestDates.count > storageMaxSize {
            systemReviewPromptRequestDates = systemReviewPromptRequestDates.suffix(storageMaxSize)
        }
    }
}

// MARK: - Auxiliary types

extension _CommonRateAppService {
    struct RateAppRequest {
        let totalBalances: [TotalBalanceProvider.TotalBalance]
        let isSelectedPageLocked: Bool
        let isSelectedPageFailedToLoadTotalBalance: Bool
        let selectedPageDisplayedNotifications: [NotificationViewInput]
    }
}

private extension _CommonRateAppService {
    enum StorageKeys: String, RawRepresentable {
        case systemReviewPromptRequestDates = "system_review_prompt_request_dates"
        case lastRequestedReviewDate = "last_requested_review_date"
        case lastRequestedReviewLaunchCount = "last_requested_review_launch_count"
        case userDismissedLastRequestedReview = "user_dismissed_last_requested_review"
    }
}

// MARK: - Constants

private extension _CommonRateAppService {
    enum Constants {
        // MARK: - Constants that control the behavior of the rate app sheet itself

        /// The user interacted with the review prompt.
        static let normalReviewRequestNumberOfLaunchesInterval = 3
        /// The user dismissed the review prompt w/o interaction.
        static let dismissedReviewRequestNumberOfLaunchesInterval = 20
        /// Three days.
        static let reviewRequestTimeInterval: TimeInterval = 3600 * 24 * 3

        static let forbiddenSeverityLevels: Set<NotificationView.Severity> = [
            .warning,
            .critical,
        ]

        // MARK: - Constants that control the behavior of the system rate app prompt (`SKStoreReviewController`)

        /// See https://developer.apple.com/documentation/storekit/requesting_app_store_reviews for details.
        static let systemReviewPromptMaxCountPerYear = 3
        /// Years, see https://developer.apple.com/documentation/storekit/requesting_app_store_reviews for details.
        static let systemReviewPromptTimeWindowSize = 1
        /// For storage trimming.
        static let systemReviewPromptRequestDatesMaxSize = 5
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
