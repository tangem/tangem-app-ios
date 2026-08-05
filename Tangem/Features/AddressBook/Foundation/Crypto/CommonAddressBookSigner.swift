//
//  CommonAddressBookSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct CommonAddressBookSigner: AddressBookSigning {
    let signerFactory: TangemSignerFactory

    func sign(digests: [Data], walletPublicKey: Data) async throws -> [Data] {
        guard !digests.isEmpty else {
            return []
        }

        let publicKey = Wallet.PublicKey(seedKey: walletPublicKey, derivationType: nil)

        let signatures = try await signerFactory
            .makeSigner()
            .sign(hashes: digests, walletPublicKey: publicKey)
            .async()

        guard signatures.count == digests.count else {
            throw AddressBookCryptoError.signatureCountMismatch
        }

        return signatures.map(\.signature)
    }
}
