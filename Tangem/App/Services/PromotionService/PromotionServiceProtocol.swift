//
//  PromotionServiceProtocol.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol PromotionServiceProtocol {
    var programName: String { get }
    var promoCode: String? { get }

    var readyForAwardPublisher: AnyPublisher<Void, Never> { get }

    func didBecomeReadyForAward()

    func promotionAvailable() async -> Bool

    func setPromoCode(_ promoCode: String?)
    func checkIfCanGetAward(userWalletId: String) async throws
    func claimReward(userWalletId: String, storageEntryAdding: StorageEntryAdding) async throws -> Bool

    func awardedProgramNames() -> Set<String>
    func resetAwardedPrograms()
}

private struct PromotionServiceKey: InjectionKey {
    static var currentValue: PromotionServiceProtocol = PromotionService()
}

extension InjectedValues {
    var promotionService: PromotionServiceProtocol {
        get { Self[PromotionServiceKey.self] }
        set { Self[PromotionServiceKey.self] = newValue }
    }
}
