//
//  PromotionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk
import BlockchainSdk

class PromotionService {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    let programName = "1inch"
    private let promoCodeStorageKey = "promo_code"

    #warning("[REDACTED_TODO_COMMENT]")
    private let awardBlockchain: Blockchain = .polygon(testnet: false)
    private let awardTokenAddress: String = "0x9c2c5fd7b07e95ee044ddeba0e97a665f142394f"

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

    func getReward(userWalletId: String, storageEntryAdding: StorageEntryAdding) throws {
        let blockchain: Blockchain = .tron(testnet: false)
        let derivationPath: DerivationPath? = blockchain.derivationPath()
        let blockchainNetwork = storageEntryAdding.getBlockchainNetwork(for: blockchain, derivationPath: derivationPath)
        let token: Token = .init(name: "USDT", symbol: "USDT", contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", decimalCount: 6, id: "tether")

        let entry = StorageEntry(blockchainNetwork: blockchainNetwork, token: token)
        storageEntryAdding.add(entry: entry) { result in
            print(result)
        }

        return ()

        runTask { [weak self] in
            guard let self else { return }

            if let promoCode {
                fatalError("promocode \(promoCode) exists")
            } else {
                // OLD USER

                let result = try await tangemApiService.validateOldUserPromotionEligibility(walletId: userWalletId, programName: programName)
                print(result)

                let address = "a"
                try await tangemApiService.awardOldUser(walletId: userWalletId, address: address, programName: programName)
            }
        }
    }
}
