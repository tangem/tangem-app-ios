//
//  PromoCampaignEnrollmentStateMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct PromoCampaignEnrollmentStateMapper {
    private let userWalletModels: [UserWalletModel]

    init(userWalletModels: [UserWalletModel]) {
        self.userWalletModels = userWalletModels
    }

    func mapToEntry(campaignId: Int, campaigns: [PromoCampaign]) -> Entry {
        guard let campaign = campaigns.first(where: { $0.id == campaignId }) else {
            return .precheck(.campaignUnavailable)
        }

        guard campaign.isEnrolled else {
            return .campaign(campaign)
        }

        return .alreadyEnrolled(campaign)
    }

    func mapToResultState(
        _ outcome: PromoCampaignEnrollmentOutcome,
        campaign: PromoCampaign
    ) -> PromoCampaignEnrollmentResultViewModel.State {
        let campaignName = campaign.content.title

        switch outcome {
        case .enrolled(let enrollments):
            return .enrolled(campaignName: campaignName, walletCount: enrollments.count)
        case .alreadyEnrolled(let enrollments):
            return .alreadyEnrolled(campaignName: campaignName, wallets: mapToWallets(enrollments))
        case .partiallyEnrolled(let enrolled, let alreadyEnrolled):
            return .partiallyEnrolled(
                campaignName: campaignName,
                enrolledWallets: mapToEnrolledWalletViewModels(enrolled + alreadyEnrolled)
            )
        case .unavailable:
            return .campaignUnavailable
        case .temporarilyUnavailable:
            return .temporarilyUnavailable
        case .failed:
            return .failed
        }
    }
}

// MARK: - Entry

extension PromoCampaignEnrollmentStateMapper {
    enum Entry {
        case campaign(PromoCampaign)
        case alreadyEnrolled(PromoCampaign)
        case precheck(PromoCampaignPrecheckViewModel.State)
    }
}

// MARK: - Private

private extension PromoCampaignEnrollmentStateMapper {
    func mapToWallets(_ enrollments: [PromoCampaignEnrollment]) -> [PromoCampaignEnrollmentWallet] {
        enrollments.compactMap { enrollment in
            userWalletModel(for: enrollment).map { mapToWallet($0, payoutAddress: enrollment.payout?.userAddress) }
        }
    }

    func mapToWallet(_ userWalletModel: UserWalletModel, payoutAddress: String?) -> PromoCampaignEnrollmentWallet {
        PromoCampaignEnrollmentWallet(
            name: userWalletModel.name,
            subtitle: userWalletModel.cardSetLabel,
            imageProvider: userWalletModel.walletImageProvider,
            payout: payoutAddress.map { PromoCampaignEnrollmentWallet.Payout(address: $0) }
        )
    }

    func mapToEnrolledWalletViewModels(_ enrollments: [PromoCampaignEnrollment]) -> [PromoCampaignEnrolledWalletViewModel] {
        let enrolledWalletIds = Set(enrollments.map(\.userWalletId))

        return userWalletModels
            .filter { enrolledWalletIds.contains($0.userWalletId) }
            .map { PromoCampaignEnrolledWalletViewModel(userWalletModel: $0) }
    }

    func userWalletModel(for enrollment: PromoCampaignEnrollment) -> UserWalletModel? {
        userWalletModels.first { $0.userWalletId == enrollment.userWalletId }
    }
}
