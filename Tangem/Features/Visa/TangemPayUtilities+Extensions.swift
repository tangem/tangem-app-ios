//
//  TangemPayUtilities+Extensions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemPay
import TangemVisa

extension TangemPayUtilities {
    @Injected(\.tangemPayAuthorizationTokensRepository)
    private static var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

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

    /// Hardcoded constant USD fiat item for Tangem Pay
    static var fiatItem: FiatItem {
        FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: "USD"),
            currencyCode: "USD",
            fractionDigits: 2
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

    static func getCustomerWalletAddressAndAuthorizationTokens(
        customerWalletId: String,
        keysRepository: KeysRepository
    ) -> (customerWalletAddress: String, tokens: TangemPayAuthorizationTokens)? {
        guard let walletPublicKey = TangemPayUtilities.getKey(from: keysRepository),
              let customerWalletAddress = try? TangemPayUtilities.makeAddress(using: walletPublicKey),
              // If there was no refreshToken saved - means user never got tangem pay offer
              let tokens = tangemPayAuthorizationTokensRepository.getToken(forCustomerWalletId: customerWalletId)
        else {
            return nil
        }

        return (customerWalletAddress, tokens)
    }
}
