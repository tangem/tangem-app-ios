//
//  SolanaTokenAccountSelector.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

enum SolanaTokenAccountSelector {
    static func uniqueAccountsByMint(
        _ accounts: [SolanaTokenAccountInfoResponse],
        ownerAccountId: String
    ) -> [String: SolanaTokenAccountInfoResponse] {
        Dictionary(grouping: accounts, by: \.mint).compactMapValues { accountsForMint in
            guard
                let mint = accountsForMint.first?.mint,
                let address = preferredAccountAddress(
                    from: accountsForMint.map(\.address),
                    mint: mint,
                    ownerAccountId: ownerAccountId
                )
            else {
                return nil
            }

            return accountsForMint.first { $0.address == address }
        }
    }

    /// Send always spends from the associated token account, so the UI balance and token history for a mint
    /// must come from that account when it exists. Extra token accounts for the same mint are ignored.
    static func preferredAccountAddress(
        from addresses: [String],
        mint: String,
        ownerAccountId: String
    ) -> String? {
        let associatedAddresses = Set(
            [PublicKey.tokenProgramId, PublicKey.token2022ProgramId].compactMap { programId in
                associatedTokenAddress(ownerAccountId: ownerAccountId, mintAddress: mint, tokenProgramId: programId)
            }
        )

        if let associatedAddress = addresses.first(where: { associatedAddresses.contains($0) }) {
            return associatedAddress
        }

        // The mint has no ATA yet; keep the first account so discovery still surfaces the token.
        return addresses.first
    }
}

private extension SolanaTokenAccountSelector {
    static func associatedTokenAddress(
        ownerAccountId: String,
        mintAddress: String,
        tokenProgramId: PublicKey
    ) -> String? {
        guard
            let owner = PublicKey(string: ownerAccountId),
            let mint = PublicKey(string: mintAddress),
            case .success(let associatedAddress) = PublicKey.associatedTokenAddress(
                walletAddress: owner,
                tokenMintAddress: mint,
                tokenProgramId: tokenProgramId
            )
        else {
            return nil
        }

        return associatedAddress.base58EncodedString
    }
}
