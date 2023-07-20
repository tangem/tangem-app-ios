//
//  PromotionServiceProtocol.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol PromotionServiceProtocol {
    var currentProgramName: String { get }
    var questionnaireFinished: Bool { get }
    var promoCode: String? { get }

    var awardAmount: Int? { get }
    var promotionAvailable: Bool { get }

    var readyForAwardPublisher: AnyPublisher<Void, Never> { get }

    func didBecomeReadyForAward()

    func checkPromotion(isNewCard: Bool, userWalletId: String?, timeout: TimeInterval?) async

    func setQuestionnaireFinished(_ finished: Bool)

    func setPromoCode(_ promoCode: String?)
    func checkIfCanGetAward(userWalletId: String) async throws
    func claimReward(userWalletId: String, storageEntryAdding: StorageEntryAdding) async throws -> Blockchain?

    func awardedPromotionNames() -> Set<String>
    func resetAward(cardId: String) async throws

    func finishedPromotionNames() -> Set<String>
    func resetFinishedPromotions()
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
