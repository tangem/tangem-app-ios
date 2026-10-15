//
//  SolanaALTSignerGuard.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

enum SolanaALTSignerGuard {
    static func validate(header: MessageHeader, staticAccountKeys: [PublicKey], walletPublicKey: PublicKey) throws {
        guard header.numRequiredSignatures == 1, staticAccountKeys.first == walletPublicKey else {
            throw SolanaBSDKError.walletIsNotSoleRequiredSigner
        }
    }
}
