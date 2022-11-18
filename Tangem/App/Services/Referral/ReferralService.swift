//
//  ReferralService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSdk

protocol ReferralService {
    func loadReferralProgramInfo() async throws -> ReferralProgramInfo
    func participateInReferralProgram(using token: ReferralProgramInfo.Conditions.Token, with address: String) async throws -> ReferralProgramInfo
}

class CommonReferralService {
    @Injected(\.tangemApiService) private var apiService: TangemApiService

    private let userWalletId: Data

    init(userWalletId: Data) {
        self.userWalletId = userWalletId
    }
}

extension CommonReferralService: ReferralService {
    func loadReferralProgramInfo() async throws -> ReferralProgramInfo {
        try await apiService.loadReferralProgramInfo(for: userWalletId.hexString)
    }

    func participateInReferralProgram(using token: ReferralProgramInfo.Conditions.Token, with address: String) async throws -> ReferralProgramInfo {
        let request = ReferralParticipationRequestBody(
            walletId: userWalletId.hexString,
            networkId: token.networkId,
            tokenId: token.id,
            address: address
        )
        return try await apiService.participateInReferralProgram(with: request)
    }
}
