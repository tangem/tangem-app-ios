//
//  CommonReferralProgramInfoRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonReferralProgramInfoRepository {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let infoSubject = CurrentValueSubject<[UserWalletId: ReferralProgramInfo], Never>([:])
    private let storeLock = OSAllocatedUnfairLock()
}

// MARK: - ReferralProgramInfoRepository

extension CommonReferralProgramInfoRepository: ReferralProgramInfoRepository {
    func infoPublisher(for userWalletId: UserWalletId) -> AnyPublisher<ReferralProgramInfo?, Never> {
        infoSubject
            .map { $0[userWalletId] }
            .eraseToAnyPublisher()
    }

    func loadInfo(for userWalletId: UserWalletId) async throws -> ReferralProgramInfo {
        let info = try await tangemApiService.loadReferralProgramInfo(
            for: userWalletId.stringValue,
            expectedAwardsLimit: ReferralConstants.expectedAwardsFetchLimit
        )
        store(info, for: userWalletId)

        return info
    }

    func store(_ info: ReferralProgramInfo, for userWalletId: UserWalletId) {
        storeLock.withLock {
            infoSubject.value[userWalletId] = info
        }
    }
}
