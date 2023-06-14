//
//  PromotionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk
import BlockchainSdk

class PromotionService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    var readyForAwardPublisher: AnyPublisher<Void, Never> {
        readyForAwardSubject.eraseToAnyPublisher()
    }

    let programName = "1inch"
    private let promoCodeStorageKey = "promo_code"
    private let programsWithSuccessfullAwardsStorageKey = "programs_with_successfull_awards"

    private let readyForAwardSubject = PassthroughSubject<Void, Never>()

    init() {}
}

extension PromotionService: PromotionServiceProtocol {
    var promoCode: String? {
        let secureStorage = SecureStorage()
        guard
            let promoCodeData = try? secureStorage.get(promoCodeStorageKey),
            let promoCode = String(data: promoCodeData, encoding: .utf8)
        else {
            return nil
        }

        return promoCode
    }

    func didBecomeReadyForAward() {
        readyForAwardSubject.send(())
    }

    func promotionAvailability(timeout: TimeInterval?) async -> PromotionAvailability {
        guard
            FeatureProvider.isAvailable(.learnToEarn),
            !currentProgramWasAwarded()
        else {
            return PromotionAvailability(isAvailable: false, awardAmount: .zero)
        }

        let timeout: TimeInterval = 5
        do {
            return try await fetchPromotionAvailability(timeout: timeout)
        } catch {
            return PromotionAvailability(isAvailable: false, awardAmount: .zero)
        }
    }

    func setPromoCode(_ promoCode: String?) {
        do {
            let secureStorage = SecureStorage()

            if let promoCode {
                guard let promoCodeData = promoCode.data(using: .utf8) else { return }

                try secureStorage.store(promoCodeData, forKey: promoCodeStorageKey)
            } else {
                try secureStorage.delete(promoCodeStorageKey)
            }
        } catch {
            AppLog.shared.error(error)
            AppLog.shared.error("Failed to update promo code")
        }
    }

    func checkIfCanGetAward(userWalletId: String) async throws {
        if let promoCode {
            try await tangemApiService.validateNewUserPromotionEligibility(walletId: userWalletId, code: promoCode)
        } else {
            try await tangemApiService.validateOldUserPromotionEligibility(walletId: userWalletId, programName: programName)
        }
    }

    func claimReward(userWalletId: String, storageEntryAdding: StorageEntryAdding) async throws -> Bool {
        guard let address = try await rewardAddress(storageEntryAdding: storageEntryAdding) else { return false }

        if let promoCode {
            try await tangemApiService.awardNewUser(walletId: userWalletId, address: address, code: promoCode)
        } else {
            try await tangemApiService.awardOldUser(walletId: userWalletId, address: address, programName: programName)
        }

        markCurrentProgramAsAwarded(true)

        return true
    }

    func awardedProgramNames() -> Set<String> {
        do {
            let storage = SecureStorage()
            guard let data = try storage.get(programsWithSuccessfullAwardsStorageKey) else { return [] }
            return try JSONDecoder().decode(Set<String>.self, from: data)
        } catch {
            AppLog.shared.error(error)
            AppLog.shared.debug("Failed to get awarded programs")
            return []
        }
    }

    func resetAwardedPrograms() {
        if AppEnvironment.current.isProduction {
            AppLog.shared.debug("Trying to reset awarded programs in production. Not allowed")
            fatalError("Trying to reset awarded programs in production. Not allowed")
        }

        saveAwardedProgramNames([])
    }
}

extension PromotionService {
    private func fetchPromotionAvailability(timeout: TimeInterval) async throws -> PromotionAvailability {
        let promotion = try await tangemApiService.promotion(programName: programName, timeout: timeout)

        let isAvailable = (promotion.status == .active)

        let awardAmount: Double
        if promoCode != nil {
            awardAmount = promotion.awardForNewCard
        } else {
            awardAmount = promotion.awardForOldCard
        }

        return PromotionAvailability(isAvailable: isAvailable, awardAmount: Decimal(floatLiteral: awardAmount))
    }

    private func rewardAddress(storageEntryAdding: StorageEntryAdding) async throws -> String? {
        let promotion = try await tangemApiService.promotion(programName: programName, timeout: nil)

        guard
            let awardBlockchain = Blockchain(from: promotion.awardPaymentToken.networkId),
            let awardToken = promotion.awardPaymentToken.storageToken
        else {
            throw TangemAPIError(code: .decode)
        }

        let derivationPath: DerivationPath? = awardBlockchain.derivationPath()
        let blockchainNetwork = storageEntryAdding.getBlockchainNetwork(for: awardBlockchain, derivationPath: derivationPath)

        let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: awardToken)

        do {
            return try await storageEntryAdding.add(entry: entry)
        } catch {
            if error.toTangemSdkError().isUserCancelled {
                return nil
            } else {
                throw error
            }
        }
    }

    private func currentProgramWasAwarded() -> Bool {
        awardedProgramNames().contains(programName)
    }

    private func markCurrentProgramAsAwarded(_ hasBeenAwarded: Bool) {
        let awardedProgramNames = awardedProgramNames()

        var newAwardedProgramNames = awardedProgramNames
        if hasBeenAwarded {
            newAwardedProgramNames.insert(programName)
        } else {
            newAwardedProgramNames.remove(programName)
        }

        guard awardedProgramNames != newAwardedProgramNames else { return }

        saveAwardedProgramNames(newAwardedProgramNames)
    }

    private func saveAwardedProgramNames(_ programNames: Set<String>) {
        do {
            let data = try JSONEncoder().encode(programNames)

            let storage = SecureStorage()
            try storage.store(data, forKey: programsWithSuccessfullAwardsStorageKey)
        } catch {
            AppLog.shared.error(error)
            AppLog.shared.debug("Failed to set awarded programs")
        }
    }
}
