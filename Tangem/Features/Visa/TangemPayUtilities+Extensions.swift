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
    enum Constants {
        static let usdcSymbol = "USDC"
        static let usdtSymbol = "USDT"
        static let usdcCoinId = "usd-coin"
        static let usdtCoinId = "tether"
        static let usdcContractAddress = "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"

        /// The account's stables are six-decimal everywhere except BNB Smart Chain, whose
        /// Binance-Peg USDC and USDT carry eighteen.
        static let defaultTokenDecimalCount = 6
        static let bscTokenDecimalCount = 18
    }

    @Injected(\.keysManager)
    private static var keysManager: KeysManager

    private static let bscChainIds = Set(
        [Blockchain.bsc(testnet: false), .bsc(testnet: true)].compactMap(\.chainId)
    )

    private static let blockchainsByChainId: [Int: Blockchain] = Blockchain.allMainnetCases
        .reduce(into: [:]) { result, blockchain in
            guard let chainId = blockchain.chainId else {
                return
            }

            result[chainId] = blockchain
        }

    /// The balance endpoint reports no decimals, so they are kept here until it does.
    static func tokenDecimalCount(chainId: Int?) -> Int {
        guard let chainId, bscChainIds.contains(chainId) else {
            return Constants.defaultTokenDecimalCount
        }

        return Constants.bscTokenDecimalCount
    }

    /// The coin ids the icon and the market rate are looked up by; the balance endpoint carries
    /// a symbol only. Anything else the account starts holding shows up without either.
    static func tokenId(symbol: String) -> String? {
        switch symbol.uppercased() {
        case Constants.usdcSymbol: Constants.usdcCoinId
        case Constants.usdtSymbol: Constants.usdtCoinId
        default: nil
        }
    }

    /// Hardcoded USDC token on visa blockchain network (currently - Polygon)
    static var usdcTokenItem: TokenItem {
        TokenItem.token(
            Token(
                name: Constants.usdcSymbol,
                symbol: Constants.usdcSymbol,
                contractAddress: Constants.usdcContractAddress,
                decimalCount: Constants.defaultTokenDecimalCount,
                id: Constants.usdcCoinId,
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

    /// The chain id decides — the withdraw request is addressed by it — and the name table covers
    /// what a mainnet chain-id table can't: Tron, which has no EVM chain id, and testnets.
    static func blockchain(for network: TangemPayBalance.Network) -> Blockchain? {
        if !network.isTestnet, let blockchain = blockchainsByChainId[network.chainId] {
            return blockchain
        }

        guard let named = blockchain(name: network.name, isTestnet: network.isTestnet) else {
            return nil
        }

        // Testnets are taken at their name: the SDK's testnet chain ids trail the networks.
        guard !network.isTestnet, let namedChainId = named.chainId else {
            return named
        }

        return namedChainId == network.chainId ? named : nil
    }

    private static func blockchain(name: String, isTestnet: Bool) -> Blockchain? {
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
