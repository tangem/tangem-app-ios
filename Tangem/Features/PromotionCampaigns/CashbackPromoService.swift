//
//  CashbackPromoService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CashbackPromoService {
    private let repository = CashbackPromoRepository()

    func campaign(id: String) async -> CampaignBannerData? {
        await repository.campaign(id: id)
    }

    func register(_ registration: CashbackRegistration) async throws -> CashbackRegistrationResult {
        try await repository.register(registration)
    }
}

// MARK: - Types

struct CashbackRegistration {
    let campaignId: String
    let walletIds: [String]
    let tokenReward: TokenReward

    struct TokenReward {
        let networkId: String
        let userAddress: String
        let tokenAddress: String?
    }
}

enum CashbackRegistrationResult {
    case registered
    case alreadyEnrolled
}

// MARK: - Repository

private final class CashbackPromoRepository {
    @Injected(\.promotionCampaignsRepository) private var promotionCampaignsRepository: PromotionCampaignsRepository
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func campaign(id: String) async -> CampaignBannerData? {
        guard let userWalletId = userWalletRepository.selectedModel?.userWalletId.stringValue else {
            return nil
        }

        return await promotionCampaignsRepository.campaignBannerData(userWalletId: userWalletId, campaignName: id)
    }

    func register(_ registration: CashbackRegistration) async throws -> CashbackRegistrationResult {
        let request = PromotionRegistrationDTO.Request(
            campaignId: registration.campaignId,
            walletIds: registration.walletIds,
            tokenReward: .init(
                tokenAddress: registration.tokenReward.tokenAddress,
                networkId: registration.tokenReward.networkId,
                userAddress: registration.tokenReward.userAddress
            )
        )

        let response = try await tangemApiService.registerForPromotionCampaign(request: request)

        switch response.status {
        case .saved: return .registered
        case .alreadyExists: return .alreadyEnrolled
        }
    }
}
