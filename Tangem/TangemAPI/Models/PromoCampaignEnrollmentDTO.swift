//
//  PromoCampaignEnrollmentDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum PromoCampaignEnrollmentDTO {}

// MARK: - Request

extension PromoCampaignEnrollmentDTO {
    struct Request: Encodable, Equatable {
        let enrollments: [Enrollment]
    }

    struct Enrollment: Encodable, Equatable {
        let walletId: String
        let walletType: PromoCampaignsDTO.Request.WalletType
        let batchId: String?
        let userAddress: String?
        let tokenAddress: String?
        let networkId: String?
        let tokenId: String?
        let main: Bool
    }
}

extension PromoCampaignEnrollmentDTO.Enrollment {
    init(wallet: PromoCampaignWallet, userAddress: String?, payoutToken: CampaignEligibleToken?, isMain: Bool) {
        let walletType: PromoCampaignsDTO.Request.WalletType
        let batchId: String?

        switch wallet.identity {
        case .card(let cardBatchId):
            walletType = .card
            batchId = cardBatchId
        case .mobile:
            walletType = .mobile
            batchId = nil
        }

        self.init(
            walletId: wallet.userWalletId.stringValue,
            walletType: walletType,
            batchId: batchId,
            userAddress: userAddress,
            tokenAddress: payoutToken?.tokenAddress,
            networkId: payoutToken?.networkId,
            tokenId: payoutToken?.tokenId,
            main: isMain
        )
    }
}

// MARK: - Response

extension PromoCampaignEnrollmentDTO {
    struct Response: Decodable {
        @LossyArray private(set) var results: [WalletResult]
    }

    struct WalletResult: Decodable {
        let walletId: String
        let status: Status
        let payout: Payout?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            walletId = try container.decode(String.self, forKey: .walletId)
            status = try container.decode(Status.self, forKey: .status)
            payout = try? container.decodeIfPresent(Payout.self, forKey: .payout)
        }

        private enum CodingKeys: String, CodingKey {
            case walletId
            case status
            case payout
        }
    }

    enum Status: String, Decodable {
        case enrolled
        case alreadyEnrolled = "already_enrolled"
        case ineligible
    }

    struct Payout: Decodable {
        let userAddress: String
        let tokenAddress: String
        let networkId: String
    }
}
