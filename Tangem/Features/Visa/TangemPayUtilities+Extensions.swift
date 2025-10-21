//
//  TangemPayUtilities+Extensions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemVisa

extension TangemPayUtilities {
    /// Hardcoded USDC token on visa blockchain network (currently - Polygon)
    static var usdcTokenItem: TokenItem {
        TokenItem.token(
            Token(
                name: "USDC",
                symbol: "USDC",
                contractAddress: "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359",
                decimalCount: 6,
                id: "usd-coin",
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(
                TangemPayUtilities.blockchain,
                derivationPath: TangemPayUtilities.derivationPath
            )
        )
    }

    static func getKey(from repository: KeysRepository) -> Wallet.PublicKey? {
        return repository.keys
            .first(where: { $0.curve == TangemPayUtilities.mandatoryCurve })
            .flatMap { key -> Wallet.PublicKey? in
                guard let derivedKey = key.derivedKeys[TangemPayUtilities.derivationPath]
                else {
                    return nil
                }

                return Wallet.PublicKey(
                    seedKey: key.publicKey,
                    derivationType: .plain(
                        .init(
                            path: TangemPayUtilities.derivationPath,
                            extendedPublicKey: derivedKey
                        )
                    )
                )
            }
    }
}
