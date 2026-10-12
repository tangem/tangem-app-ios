//
//  TangemPayCampaignResolver.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPay

struct TangemPayCampaignResolver {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private let campaignKey: String
    private let availabilityService = TangemPayAvailabilityServiceBuilder().build()

    init(campaignKey: String) {
        self.campaignKey = campaignKey
    }

    func resolve() async throws -> TangemPayCampaignResolution {
        guard try await isCampaignValid() else {
            return .unavailable
        }

        // `validateDeeplink` has already turned away an unknown key, so missing art means the placeholder.
        let cardArtURL = try await availabilityService.getCampaignImages(deeplinkValue: campaignKey).mainImageURL

        guard let (userWalletModel, tangemPayAccount) = await walletWithTangemPay() else {
            let mode: TangemPayCampaignLanding.Mode = userWalletRepository.models.isEmpty ? .noWallet : .noPay
            return .landing(TangemPayCampaignLanding(cardArtURL: cardArtURL, mode: mode))
        }

        guard let offer = try await tangemPayAccount.loadCampaignCardIssueOffer(deeplinkValue: campaignKey) else {
            return .unavailable
        }

        return .issueCard(
            TangemPayCampaignIssueCard(
                cardArtURL: offer.mainImageURL ?? cardArtURL,
                userWalletModel: userWalletModel,
                tangemPayAccount: tangemPayAccount,
                fee: offer.fee
            )
        )
    }
}

private extension TangemPayCampaignResolver {
    func isCampaignValid() async throws -> Bool {
        let response = try await availabilityService.validateDeeplink(deeplinkString: campaignDeeplinkString)
        switch response.status {
        case .valid: return true
        case .invalid: return false
        }
    }

    func walletWithTangemPay() async -> (UserWalletModel, TangemPayAccount)? {
        let accountModels = userWalletRepository.models
            .filter(\.supportsTangemPay)
            .compactMap { userWalletModel in
                AccountModelsAggregator(.tangemPay)
                    .model(from: userWalletModel.accountModelsManager)
                    .map { (userWalletModel, $0) }
            }

        await waitForSettledStates(of: accountModels.map { _, accountModel in accountModel })

        return accountModels
            .lazy
            .compactMap { userWalletModel, accountModel in
                accountModel.state?.tangemPayAccount.map { (userWalletModel, $0) }
            }
            .first
    }

    /// A wallet that is not a Paera customer keeps a `nil` state, which `statePublisher` drops — waiting on
    /// those would stall the landing for the whole timeout and never learn anything.
    func waitForSettledStates(of accountModels: [any TangemPayAccountModel]) async {
        let publishers = accountModels
            .filter { $0.state?.isSettling == true }
            .map {
                $0.statePublisher
                    .filter { !$0.isSettling }
                    .first()
                    .eraseToAnyPublisher()
            }

        guard publishers.isNotEmpty else { return }

        _ = try? await Publishers.MergeMany(publishers)
            .collect()
            .timeout(.seconds(Constants.stateSettleTimeout), scheduler: DispatchQueue.main)
            .async()
    }

    var campaignDeeplinkString: String {
        "\(IncomingActionConstants.appScheme)marketing/\(campaignKey)"
    }
}

private extension TangemPayCampaignResolver {
    enum Constants {
        static let stateSettleTimeout: TimeInterval = 5
    }
}
