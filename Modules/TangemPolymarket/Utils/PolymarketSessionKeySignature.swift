//
//  PolymarketSessionKeySignature.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public enum PolymarketSessionKeySignatureError: Error, Equatable {
    case invalidAddress(String)
    case invalidSignature
}

public enum PolymarketSessionKeySignature {
    public static func envelope(
        depositWalletSignature: String,
        sessionKeyAddress: String
    ) throws(PolymarketSessionKeySignatureError) -> String {
        guard let signerId = PolymarketABIWord.address(sessionKeyAddress) else {
            throw .invalidAddress(sessionKeyAddress)
        }

        let signature = depositWalletSignature.removeHexPrefix().lowercased()

        guard !signature.isEmpty, signature.count.isMultiple(of: 2), signature.allSatisfy(\.isASCIIHexDigit) else {
            throw .invalidSignature
        }

        let digitCount = PolymarketABIWord.digitCount
        let paddingDigitCount = (digitCount - signature.count % digitCount) % digitCount

        return [
            signerId,
            PolymarketABIWord.zero,
            PolymarketABIWord.uint(Constants.signatureOffset),
            PolymarketABIWord.uint(UInt64(signature.count / 2)),
            signature + String(repeating: "0", count: paddingDigitCount),
            Constants.magicSuffix,
        ].joined().addHexPrefix()
    }
}

// MARK: - Private implementation

private extension PolymarketSessionKeySignature {
    enum Constants {
        static let signatureOffset = UInt64(3 * PolymarketABIWord.byteCount)
        static let magicSuffix = String(repeating: "6492", count: 16)
    }
}
