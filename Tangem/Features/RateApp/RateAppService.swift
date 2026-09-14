//
//  RateAppService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

/// Decides only whether this user may be asked at all; whether a given main screen page renders
/// the prompt is up to `CommonRateAppController`.
final class RateAppService {
    var isEligiblePublisher: AnyPublisher<Bool, Never> {
        Publishers
            .MergeMany([
                $userRespondedToLastRequestedReview.mapToVoid().eraseToAnyPublisher(),
                $userDismissedLastRequestedReviewDate.mapToVoid().eraseToAnyPublisher(),
                $userDismissedLastRequestedReviewLaunchCount.mapToVoid().eraseToAnyPublisher(),
                $positiveBalanceAppearanceDate.mapToVoid().eraseToAnyPublisher(),
                $positiveBalanceAppearanceLaunchCount.mapToVoid().eraseToAnyPublisher(),
            ])
            .withWeakCaptureOf(self)
            .map { service, _ in service.isEligible }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    @AppStorageCompat(StorageKeys.didAttemptMigrationFromLegacyRateApp)
    private var didAttemptMigrationFromLegacyRateApp: Bool = false

    @AppStorageCompat(StorageKeys.positiveBalanceAppearanceDate)
    private var positiveBalanceAppearanceDate: Date? = nil

    @AppStorageCompat(StorageKeys.positiveBalanceAppearanceLaunchCount)
    private var positiveBalanceAppearanceLaunchCount: Int? = nil

    @AppStorageCompat(StorageKeys.userRespondedToLastRequestedReview)
    private var userRespondedToLastRequestedReview: Bool = false

    @AppStorageCompat(StorageKeys.userDismissedLastRequestedReviewDate)
    private var userDismissedLastRequestedReviewDate: Date? = nil

    @AppStorageCompat(StorageKeys.userDismissedLastRequestedReviewLaunchCount)
    private var userDismissedLastRequestedReviewLaunchCount: Int? = nil

    private var userDismissedLastRequestedReview: Bool {
        return userDismissedLastRequestedReviewDate != nil && userDismissedLastRequestedReviewLaunchCount != nil
    }

    private var currentLaunchCount: Int { AppSettings.shared.numberOfLaunches }

    private var requiredNumberOfLaunches: Int {
        return userDismissedLastRequestedReview
            ? Constants.dismissedReviewRequestNumberOfLaunchesInterval
            : Constants.normalReviewRequestNumberOfLaunchesInterval
    }

    private var isEligible: Bool {
        if userRespondedToLastRequestedReview {
            return false
        }

        if positiveBalanceAppearanceDate == nil {
            return false
        }

        guard
            let date = (userDismissedLastRequestedReviewDate ?? positiveBalanceAppearanceDate),
            abs(date.timeIntervalSinceNow) >= Constants.reviewRequestTimeInterval
        else {
            return false
        }

        guard
            let launchCount = (userDismissedLastRequestedReviewLaunchCount ?? positiveBalanceAppearanceLaunchCount),
            currentLaunchCount - launchCount >= requiredNumberOfLaunches
        else {
            return false
        }

        return true
    }

    init() {
        migrateFromLegacyRateAppIfNeeded()
    }

    func registerBalances(of walletModels: [any WalletModel]) {
        guard
            positiveBalanceAppearanceDate == nil,
            walletModels.contains(where: { !$0.isEmpty }) // Check if at least one wallet has a non-empty (non-zero) balance
        else {
            return
        }

        positiveBalanceAppearanceDate = Date()
        positiveBalanceAppearanceLaunchCount = currentLaunchCount
    }

    func respondToRateAppDialog(with response: RateAppResponse) {
        sendAnalyticsEvent(for: response)

        switch response {
        case .positive,
             .negative:
            userRespondedToLastRequestedReview = true
        case .dismissed:
            userDismissedLastRequestedReviewDate = Date()
            userDismissedLastRequestedReviewLaunchCount = currentLaunchCount
        }
    }

    private func sendAnalyticsEvent(for response: RateAppResponse) {
        let parameterValue: Analytics.ParameterValue

        switch response {
        case .positive:
            parameterValue = .appStoreReview
        case .negative:
            parameterValue = .feedbackEmail
        case .dismissed:
            parameterValue = .appRateDismissed
        }

        Analytics.log(.mainNoticeRateTheApp, params: [.result: parameterValue])
    }

    private func migrateFromLegacyRateAppIfNeeded() {
        if didAttemptMigrationFromLegacyRateApp {
            return
        }

        didAttemptMigrationFromLegacyRateApp = true

        // A fresh install without using the old version with legacy `RateAppService`
        if currentLaunchCount <= 1 {
            return
        }

        // An upgrade from the previous version with legacy `RateAppService`, therefore we have to
        // postpone the upcoming rate app request even if all conditions for it are met

        if positiveBalanceAppearanceDate != nil {
            positiveBalanceAppearanceDate = Date()
        }

        if positiveBalanceAppearanceLaunchCount != nil {
            positiveBalanceAppearanceLaunchCount = currentLaunchCount
        }
    }
}

// MARK: - Auxiliary types

private extension RateAppService {
    enum StorageKeys: String, RawRepresentable {
        case positiveBalanceAppearanceDate = "tangem_tap_positive_balace_appearance_date"
        case positiveBalanceAppearanceLaunchCount = "tangem_tap_positive_balance_appearance_launch"
        case userDismissedLastRequestedReviewDate = "user_dismissed_last_requested_review_date"
        case userDismissedLastRequestedReviewLaunchCount = "user_dismissed_last_requested_review_launch_count"
        case userRespondedToLastRequestedReview = "user_responded_to_last_requested_review"
        case didAttemptMigrationFromLegacyRateApp = "did_attempt_migration_from_legacy_rate_app"
    }
}

// MARK: - Constants

private extension RateAppService {
    enum Constants {
        /// The user interacted with the review prompt.
        static let normalReviewRequestNumberOfLaunchesInterval = 3
        /// The user dismissed the review prompt w/o interaction.
        static let dismissedReviewRequestNumberOfLaunchesInterval = 20
        /// Three days.
        static let reviewRequestTimeInterval: TimeInterval = 3600 * 24 * 3
    }
}

// MARK: - DI

private struct RateAppServiceInjectionKey: InjectionKey {
    static var currentValue = RateAppService()
}

extension InjectedValues {
    var rateAppService: RateAppService {
        get { Self[RateAppServiceInjectionKey.self] }
        set { Self[RateAppServiceInjectionKey.self] = newValue }
    }
}
