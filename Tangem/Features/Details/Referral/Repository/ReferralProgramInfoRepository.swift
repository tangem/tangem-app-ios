//
//  ReferralProgramInfoRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol ReferralProgramInfoRepository: AnyObject {
    func infoPublisher(for userWalletId: UserWalletId) -> AnyPublisher<ReferralProgramInfo?, Never>
    func loadInfo(for userWalletId: UserWalletId) async throws -> ReferralProgramInfo
    func store(_ info: ReferralProgramInfo, for userWalletId: UserWalletId)
}

private struct ReferralProgramInfoRepositoryKey: InjectionKey {
    static var currentValue: ReferralProgramInfoRepository = CommonReferralProgramInfoRepository()
}

extension InjectedValues {
    var referralProgramInfoRepository: ReferralProgramInfoRepository {
        get { Self[ReferralProgramInfoRepositoryKey.self] }
        set { Self[ReferralProgramInfoRepositoryKey.self] = newValue }
    }
}
