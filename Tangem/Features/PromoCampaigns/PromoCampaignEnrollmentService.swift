//
//  PromoCampaignEnrollmentService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemNetworkUtils

protocol PromoCampaignEnrolling {
    func enroll(
        in campaign: PromoCampaign,
        from userWalletId: UserWalletId,
        payout: PromoCampaignPayoutSelection?
    ) async -> PromoCampaignEnrollmentOutcome
}

struct PromoCampaignPayoutSelection {
    let tokenItem: TokenItem
    let address: String
}

struct CommonPromoCampaignEnrollmentService {
    private let walletsProvider: PromoCampaignWalletsProviding
    private let campaignsRepository: PromoCampaignsProviding
    private let tangemApiService: TangemApiService

    init(
        walletsProvider: PromoCampaignWalletsProviding = CommonPromoCampaignWalletsProvider(),
        campaignsRepository: PromoCampaignsProviding = InjectedValues[\.promoCampaignsRepository],
        tangemApiService: TangemApiService = InjectedValues[\.tangemApiService]
    ) {
        self.walletsProvider = walletsProvider
        self.campaignsRepository = campaignsRepository
        self.tangemApiService = tangemApiService
    }
}

// MARK: - PromoCampaignEnrolling

extension CommonPromoCampaignEnrollmentService: PromoCampaignEnrolling {
    func enroll(
        in campaign: PromoCampaign,
        from userWalletId: UserWalletId,
        payout: PromoCampaignPayoutSelection?
    ) async -> PromoCampaignEnrollmentOutcome {
        let wallets = enrollingWallets(for: campaign, from: userWalletId)

        guard wallets.isNotEmpty else {
            PromotionsLogger.warning("Promo campaign \(campaign.id) has no wallet to enroll from \(userWalletId.stringValue.masked())")
            return .failed
        }

        let payoutDestination = campaign.isPayoutNeeded ? makePayoutDestination(from: payout, campaign: campaign) : nil

        if campaign.isPayoutNeeded, payoutDestination == nil {
            PromotionsLogger.warning("Promo campaign \(campaign.id) needs a payout token the selected item does not match")
            return .failed
        }

        let request = PromoCampaignEnrollmentDTO.Request(
            enrollments: wallets.map { wallet in
                PromoCampaignEnrollmentDTO.Enrollment(
                    wallet: wallet,
                    userAddress: payoutDestination?.userAddress,
                    payoutToken: payoutDestination?.token,
                    isMain: wallet.userWalletId == userWalletId
                )
            }
        )

        do {
            let response = try await tangemApiService.enrollInPromoCampaign(id: campaign.id, request: request)
            return await handle(response, wallets: wallets, campaign: campaign)
        } catch {
            return await handle(error, campaign: campaign)
        }
    }
}

// MARK: - Private

private extension CommonPromoCampaignEnrollmentService {
    func enrollingWallets(for campaign: PromoCampaign, from userWalletId: UserWalletId) -> [PromoCampaignWallet] {
        let wallets = walletsProvider.wallets

        guard let mainWallet = wallets.first(where: { $0.userWalletId == userWalletId }) else {
            return []
        }

        switch campaign.matchMode {
        case .strict:
            return [mainWallet]
        case .linkedWallet:
            return [mainWallet] + wallets.filter { $0.userWalletId != userWalletId }
        }
    }

    func makePayoutDestination(from payout: PromoCampaignPayoutSelection?, campaign: PromoCampaign) -> PayoutDestination? {
        guard let payout, let token = EligibleTokenMatcher.token(matching: payout.tokenItem, in: campaign.payoutTokens) else {
            return nil
        }

        return PayoutDestination(userAddress: payout.address, token: token)
    }

    func handle(
        _ response: PromoCampaignEnrollmentDTO.Response,
        wallets: [PromoCampaignWallet],
        campaign: PromoCampaign
    ) async -> PromoCampaignEnrollmentOutcome {
        let userWalletIds = Dictionary(
            wallets.map { ($0.userWalletId.stringValue.lowercased(), $0.userWalletId) },
            uniquingKeysWith: { first, _ in first }
        )

        var enrolled: [PromoCampaignEnrollment] = []
        var alreadyEnrolled: [PromoCampaignEnrollment] = []
        var hasIneligibleWallets = false
        var respondedWalletIds: [UserWalletId] = []

        for result in response.results {
            guard let userWalletId = userWalletIds[result.walletId.lowercased()] else {
                continue
            }

            respondedWalletIds.append(userWalletId)

            let enrollment = PromoCampaignEnrollment(
                userWalletId: userWalletId,
                payout: result.payout.map { mapToPayout($0, campaign: campaign) }
            )

            switch result.status {
            case .enrolled:
                enrolled.append(enrollment)
            case .alreadyEnrolled:
                alreadyEnrolled.append(enrollment)
            case .ineligible:
                hasIneligibleWallets = true
            }
        }

        if respondedWalletIds.isNotEmpty {
            await campaignsRepository.reloadCampaigns(for: respondedWalletIds)
        }

        switch (enrolled.isEmpty, alreadyEnrolled.isEmpty) {
        case (false, false):
            return .partiallyEnrolled(enrolled: enrolled, alreadyEnrolled: alreadyEnrolled)
        case (false, true):
            return .enrolled(enrolled)
        case (true, false):
            return .alreadyEnrolled(alreadyEnrolled)
        case (true, true):
            return hasIneligibleWallets ? .unavailable : .failed
        }
    }

    func mapToPayout(_ payout: PromoCampaignEnrollmentDTO.Payout, campaign: PromoCampaign) -> PromoCampaignPayout {
        let token = EligibleTokenMatcher.token(
            networkId: payout.networkId,
            contractAddress: payout.tokenAddress,
            in: campaign.payoutTokens
        )

        return PromoCampaignPayout(
            userAddress: payout.userAddress,
            tokenAddress: payout.tokenAddress,
            networkId: payout.networkId,
            token: token
        )
    }

    func handle(_ error: Error, campaign: PromoCampaign) async -> PromoCampaignEnrollmentOutcome {
        switch error.asMoyaError?.response?.statusCode {
        case .some(Constants.campaignNotFoundStatusCode):
            await campaignsRepository.removeCampaign(withId: campaign.id)
            return .unavailable
        case .some(Constants.campaignNotActiveStatusCode):
            return .temporarilyUnavailable
        default:
            if !error.isCancellationError {
                PromotionsLogger.error("Enrolling in promo campaign \(campaign.id)", error: error)
            }

            return .failed
        }
    }
}

// MARK: - Auxiliary types

private extension CommonPromoCampaignEnrollmentService {
    struct PayoutDestination {
        let userAddress: String
        let token: CampaignEligibleToken
    }
}

// MARK: - Constants

private extension CommonPromoCampaignEnrollmentService {
    enum Constants {
        static let campaignNotFoundStatusCode = 404
        static let campaignNotActiveStatusCode = 409
    }
}
