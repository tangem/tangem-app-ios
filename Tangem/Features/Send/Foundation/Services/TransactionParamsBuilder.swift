//
//  TransactionParamsBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import BlockchainSdk

struct TransactionParamsBuilder {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    func transactionParameters(value: String) throws -> TransactionParams {
        assert(!value.isEmpty, "Have to be checked before validation")

        switch blockchain {
        case .binance:
            return BinanceTransactionParams(memo: value)
        case .xrp:
            if let destinationTag = UInt32(value) {
                return XRPTransactionParams(destinationTag: destinationTag)
            } else {
                throw TransactionParamsBuilderError.invalidMemoDestinationTag
            }
        case .stellar:
            if let memoID = UInt64(value) {
                return StellarTransactionParams(memo: .id(memoID))
            }

            // MEMO_TEXT is limited to 28 *bytes*; a longer memo is signed by the card and then rejected by
            // Horizon as malformed, so refuse it here where the destination field shows the error.
            guard value.utf8.count <= Constants.stellarTextMemoMaxBytes else {
                throw TransactionParamsBuilderError.invalidMemoDestinationTag
            }

            return StellarTransactionParams(memo: .text(value))
        case .ton:
            return TONTransactionParams(memo: value)
        case .cosmos, .terraV1, .terraV2, .sei, .gonka:
            return CosmosTransactionParams(memo: value)
        case .algorand:
            return AlgorandTransactionParams(nonce: value)
        case .hedera:
            return HederaTransactionParams(memo: value)
        case .internetComputer:
            if let memo = UInt64(value) {
                return ICPTransactionParams(memo: memo)
            } else {
                throw TransactionParamsBuilderError.invalidMemoDestinationTag
            }
        case .casper:
            if let memo = UInt64(value) {
                return CasperTransactionParams(memo: memo)
            } else {
                throw TransactionParamsBuilderError.invalidMemoDestinationTag
            }
        case .bitcoin,
             .litecoin,
             .ethereum,
             .ethereumPoW,
             .disChain,
             .ethereumClassic,
             .rsk,
             .bitcoinCash,
             .cardano,
             .ducatus,
             .tezos,
             .dogecoin,
             .bsc,
             .polygon,
             .avalanche,
             .solana,
             .fantom,
             .polkadot,
             .kusama,
             .azero,
             .tron,
             .arbitrum,
             .dash,
             .gnosis,
             .optimism,
             .kava,
             .kaspa,
             .ravencoin,
             .cronos,
             .telos,
             .octa,
             .chia,
             .near,
             .decimal,
             .veChain,
             .xdc,
             .shibarium,
             .aptos,
             .areon,
             .playa3ullGames,
             .pulsechain,
             .aurora,
             .manta,
             .zkSync,
             .moonbeam,
             .polygonZkEVM,
             .moonriver,
             .mantle,
             .flare,
             .taraxa,
             .radiant,
             .base,
             .bittensor,
             .joystream,
             .koinos,
             .cyber,
             .blast,
             .filecoin,
             .sui,
             .energyWebEVM,
             .energyWebX,
             .core,
             .canxium,
             .chiliz,
             .xodex,
             .clore,
             .fact0rn,
             .odysseyChain,
             .bitrock,
             .apeChain,
             .sonic,
             .alephium,
             .vanar,
             .zkLinkNova,
             .pepecoin,
             .hyperliquidEVM,
             .quai,
             .scroll,
             .linea,
             .monad,
             .igra,
             .robinhood,
             .arbitrumNova,
             .plasma,
             .adi,
             .electroneum,
             .arc,
             .seiEvm:
            throw TransactionParamsBuilderError.extraIdNotSupported
        }
    }
}

private extension TransactionParamsBuilder {
    enum Constants {
        /// Stellar `MEMO_TEXT` payload limit (bytes, not characters).
        static let stellarTextMemoMaxBytes = 28
    }
}

enum TransactionParamsBuilderError: LocalizedError {
    case invalidMemoDestinationTag
    case extraIdNotSupported

    var errorDescription: String? {
        switch self {
        case .invalidMemoDestinationTag:
            return Localization.sendMemoDestinationTagError
        case .extraIdNotSupported:
            return "Blockchain don't support the extra id"
        }
    }
}
