//
//  YieldPromoStatusProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct YieldPromoState: Equatable {
    let status: YieldPromoStatus
    let daysLeftToUnlockBonus: Int?

    static let undefined = YieldPromoState(status: .undefined, daysLeftToUnlockBonus: nil)
}

final class YieldPromoStatusProvider {
    @Injected(\.yieldAPYBoostPromoRepository)
    private var yieldAPYBoostPromoRepository: YieldAPYBoostPromoRepository

    @MainActor
    func promoState(userWalletId: String, tokenItem: TokenItem, now: Date = .now) async -> YieldPromoState {
        guard let enrollmentStatus = await yieldAPYBoostPromoRepository.enrollmentStatus(userWalletId: userWalletId),
              let tokenContractAddress = tokenItem.contractAddress,
              tokenContractAddress.caseInsensitiveCompare(enrollmentStatus.contractAddress ?? "") == .orderedSame,
              tokenItem.blockchain.networkId == enrollmentStatus.networkId
        else {
            return .undefined
        }

        if enrollmentStatus.promoEnrollmentStatus == .disqualified {
            removePersistedDates(userWalletId: userWalletId)
            return .undefined
        }

        let qualificationEndDate = persistedOrFreshQualificationEndDate(from: enrollmentStatus, userWalletId: userWalletId)
        let hiddenForeverReferenceDate = qualificationEndDate ?? firstSeenCompletedDate(from: enrollmentStatus, userWalletId: userWalletId, now: now)

        if let hiddenForeverReferenceDate, Self.isPromoHiddenForever(qualificationEndDate: hiddenForeverReferenceDate, now: now) {
            return .undefined
        }

        let status: YieldPromoStatus = switch enrollmentStatus.promoEnrollmentStatus {
        case .notStarted: .notStarted
        case .active: .active
        case .completed: .completed
        case .disqualified: .undefined
        }

        let daysLeftToUnlockBonus = status == .active
            ? qualificationEndDate.flatMap { Self.daysLeft(until: $0, now: now) }
            : nil

        return YieldPromoState(status: status, daysLeftToUnlockBonus: daysLeftToUnlockBonus)
    }

    @MainActor
    func refreshPromoStatusIfEligible(userWalletId: String, tokenItem: TokenItem) async {
        guard await shouldRefreshPromoStatus(userWalletId: userWalletId, tokenItem: tokenItem) else {
            return
        }

        _ = await yieldAPYBoostPromoRepository.enrollmentStatus(userWalletId: userWalletId, forceRefresh: true)
    }

    @MainActor
    private func shouldRefreshPromoStatus(userWalletId: String, tokenItem: TokenItem) async -> Bool {
        guard let contractAddress = tokenItem.contractAddress else {
            return false
        }

        if let cachedStatus = await yieldAPYBoostPromoRepository.cachedEnrollmentStatus(userWalletId: userWalletId),
           cachedStatus.networkId == tokenItem.blockchain.networkId,
           cachedStatus.contractAddress?.caseInsensitiveCompare(contractAddress) == .orderedSame {
            return true
        }

        let eligibleTokens = await yieldAPYBoostPromoRepository.campaign(userWalletId: userWalletId)?.bannerData?.eligibleTokens ?? []
        return eligibleTokens.contains { eligible in
            eligible.networkId == tokenItem.blockchain.networkId
                && eligible.tokenAddress.caseInsensitiveCompare(contractAddress) == .orderedSame
        }
    }
}

// MARK: - Dates persistence

private extension YieldPromoStatusProvider {
    @MainActor
    func persistedOrFreshQualificationEndDate(from enrollmentStatus: YieldAPYBoostCampaign.EnrollmentStatus, userWalletId: String) -> Date? {
        let appSettings = AppSettings.shared
        let storageKey = storageKey(userWalletId: userWalletId)

        guard let freshQualificationEndDate = enrollmentStatus.qualificationEndDate else {
            return appSettings.yieldApyBoostQualificationEndDates[storageKey]
        }

        if appSettings.yieldApyBoostQualificationEndDates[storageKey] != freshQualificationEndDate {
            appSettings.yieldApyBoostQualificationEndDates[storageKey] = freshQualificationEndDate
        }

        return freshQualificationEndDate
    }

    @MainActor
    func firstSeenCompletedDate(from enrollmentStatus: YieldAPYBoostCampaign.EnrollmentStatus, userWalletId: String, now: Date) -> Date? {
        guard enrollmentStatus.promoEnrollmentStatus == .completed else {
            return nil
        }

        let appSettings = AppSettings.shared
        let storageKey = storageKey(userWalletId: userWalletId)

        if let persistedFirstSeenCompletedDate = appSettings.yieldApyBoostFirstSeenCompletedDates[storageKey] {
            return persistedFirstSeenCompletedDate
        }

        appSettings.yieldApyBoostFirstSeenCompletedDates[storageKey] = now
        return now
    }

    @MainActor
    func removePersistedDates(userWalletId: String) {
        let appSettings = AppSettings.shared
        let storageKey = storageKey(userWalletId: userWalletId)
        appSettings.yieldApyBoostQualificationEndDates[storageKey] = nil
        appSettings.yieldApyBoostFirstSeenCompletedDates[storageKey] = nil
    }

    func storageKey(userWalletId: String) -> String {
        "\(YieldAPYBoostPromoRepository.campaignName)_\(userWalletId)"
    }
}

// MARK: - Date calculations

extension YieldPromoStatusProvider {
    static func daysLeft(until qualificationEndDate: Date, now: Date = .now, calendar: Calendar = .current) -> Int? {
        let daysUntilQualificationEnd = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: qualificationEndDate)
        ).day

        guard let daysUntilQualificationEnd, daysUntilQualificationEnd >= 0 else {
            return nil
        }

        return daysUntilQualificationEnd
    }

    static func isPromoHiddenForever(qualificationEndDate: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        let daysSinceQualificationEnd = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: qualificationEndDate),
            to: calendar.startOfDay(for: now)
        ).day

        guard let daysSinceQualificationEnd else {
            return false
        }

        return daysSinceQualificationEnd > Constants.daysVisibleAfterQualificationEnd
    }

    private enum Constants {
        static let daysVisibleAfterQualificationEnd = 14
    }
}
