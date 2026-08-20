//
//  TangemPayUtilities+Extensions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemVisa
import TangemPay

extension TangemPayUtilities {
    @Injected(\.keysManager)
    private static var keysManager: KeysManager

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

    static var blockchain: Blockchain {
        .polygon(testnet: false)
    }

    /// Maps a BFF network name onto the wallet's blockchain; `nil` for networks the wallet doesn't support.
    static func blockchain(name: String, isTestnet: Bool) -> Blockchain? {
        switch name {
        case Blockchain.ethereum(testnet: false).networkId: .ethereum(testnet: isTestnet)
        case Blockchain.polygon(testnet: false).networkId: .polygon(testnet: isTestnet)
        case Blockchain.bsc(testnet: false).networkId: .bsc(testnet: isTestnet)
        case Blockchain.base(testnet: false).networkId: .base(testnet: isTestnet)
        case Blockchain.arbitrum(testnet: false).networkId: .arbitrum(testnet: isTestnet)
        case Blockchain.tron(testnet: false).networkId: .tron(testnet: isTestnet)
        default: nil
        }
    }

    static func makeAddress(using walletPublicKey: Wallet.PublicKey) throws -> String {
        try AddressServiceFactory(blockchain: TangemPayUtilities.blockchain)
            .makeAddressService()
            .makeAddress(for: walletPublicKey, with: .default)
            .value
    }

    static func getKey(from repository: KeysRepository) -> Wallet.PublicKey? {
        return repository.keys
            .first(where: { $0.curve == TangemPayUtilities.mandatoryCurve })
            .flatMap { key -> Wallet.PublicKey? in
                guard let publicKey = key.publicKey, let derivedKey = key.derivedKeys[TangemPayUtilities.derivationPath]
                else {
                    return nil
                }

                return Wallet.PublicKey(
                    seedKey: publicKey,
                    derivationType: .plain(
                        .init(
                            path: TangemPayUtilities.derivationPath,
                            extendedPublicKey: derivedKey
                        )
                    )
                )
            }
    }

    static func getBFFStaticToken() -> String {
        switch FeatureStorage.instance.visaAPIType {
        case .dev, .mock:
            keysManager.bffStaticTokenDev
        case .prod:
            keysManager.bffStaticToken
        }
    }
}

public extension RainCryptoUtilities {
    static func getRainRSAPublicKey(for apiType: VisaAPIType) throws -> String {
        try VisaConfigProvider.shared().getRainRSAPublicKey(apiType: apiType)
    }
}
