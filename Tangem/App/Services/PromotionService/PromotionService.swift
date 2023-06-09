//
//  PromotionService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 31.05.2023.
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

    var promotionAvailable: Bool {
        get async {
            guard
                FeatureProvider.isAvailable(.learnToEarn),
                !currentProgramWasAwarded()
            else {
                return false
            }

            let timeout: TimeInterval = 5
            do {
                return try await promotionIsHappeningRightNow(timeout: timeout)
            } catch {
                AppLog.shared.debug("Failed to get promotion details \(error.localizedDescription)")
                return false
            }
        }
    }

    let programName = "1inch"
    private let promoCodeStorageKey = "promo_code"
    private let programsWithSuccessfullAwardsStorageKey = "programs_with_successfull_awards"

    #warning("TODO: finalize")
    private let awardBlockchain: Blockchain = .polygon(testnet: false)
    private let awardToken: Token = .init(name: "1inch", symbol: "1INCH", contractAddress: "0x9c2c5fd7b07e95ee044ddeba0e97a665f142394f", decimalCount: 6, id: "1inch")

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
    private func promotionIsHappeningRightNow(timeout: TimeInterval) async throws -> Bool {
        let parameters = try await tangemApiService.promotion(programName: programName, timeout: timeout)
        let startDate = Date(timeIntervalSince1970: parameters.startTimestamp / 1000)
        let endDate = Date(timeIntervalSince1970: parameters.endTimestamp / 1000)

        let now = Date()
        return startDate <= now && now <= endDate
    }

    private func rewardAddress(storageEntryAdding: StorageEntryAdding) async throws -> String? {
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
