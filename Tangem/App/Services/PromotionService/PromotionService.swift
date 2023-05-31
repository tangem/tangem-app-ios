//
//  PromotionService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk

class PromotionService {
    private let promoCodeStorageKey = "promo_code"

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

    func setPromoCode(_ promoCode: String) {
        guard let promoCodeData = promoCode.data(using: .utf8) else { return }

        do {
            let secureStorage = SecureStorage()
            try secureStorage.store(promoCodeData, forKey: promoCodeStorageKey)
        } catch {
            AppLog.shared.error(error)
            AppLog.shared.error("Failed to save promo code")
        }
    }
}
