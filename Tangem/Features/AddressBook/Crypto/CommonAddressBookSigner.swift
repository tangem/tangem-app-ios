//
//  CommonAddressBookSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

struct CommonAddressBookSigner: AddressBookSigning {
    private let signer: TransactionSigner

    init(signer: TransactionSigner) {
        self.signer = signer
    }

    func sign(digests: [Data], walletPublicKey: Wallet.PublicKey) async throws -> [Data] {
        guard !digests.isEmpty else {
            return []
        }

        let signatures = try await signer
            .sign(hashes: digests, walletPublicKey: walletPublicKey)
            .async()

        guard signatures.count == digests.count else {
            throw AddressBookCryptoError.signatureCountMismatch
        }

        return signatures.map(\.signature)
    }
}
