//
//  OTPRepository.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public protocol VisaOTPRepository: AnyObject {
    func hasSavedOTP(cardId: String) throws -> Bool
    func getOTP(cardId: String) throws -> Data?
    func saveOTP(_ otp: Data, cardId: String) throws
    func removeOTP(cardId: String) throws
}

final class CommonVisaOTPRepository {
    let secureStorage = SecureStorage()

    private let otpStorageKeyPrefix = "tangem_visa_otp_"

    private func otpStorageKey(cardId: String) -> String {
        return otpStorageKeyPrefix + cardId
    }
}

extension CommonVisaOTPRepository: VisaOTPRepository {
    func hasSavedOTP(cardId: String) throws -> Bool {
        let otp = try getOTP(cardId: cardId)
        return otp != nil
    }

    func getOTP(cardId: String) throws -> Data? {
        try secureStorage.get(otpStorageKey(cardId: cardId))
    }

    func saveOTP(_ otp: Data, cardId: String) throws {
        try secureStorage.store(otp, forKey: otpStorageKey(cardId: cardId))
    }

    func removeOTP(cardId: String) throws {
        try secureStorage.delete(otpStorageKey(cardId: cardId))
    }
}
