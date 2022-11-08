//
//  ExchangeCurrency.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct ExchangeCurrency {
    let type: Currency

    var name: String?
    var symbol: String?
    var decimalCount: Decimal?
    var imageURL: URL?

    init(
        type: ExchangeCurrency.Currency,
        name: String? = nil,
        symbol: String? = nil,
        decimalCount: Decimal? = nil,
        imageURL: URL? = nil
    ) {
        self.type = type
        self.name = name
        self.symbol = symbol
        self.decimalCount = decimalCount
        self.imageURL = imageURL
    }

    var contractAddress: String {
        type.contractAddress
    }

    func createAmount(with decimal: Decimal) -> Amount {
        switch type {
        case .coin(let blockchainNetwork):
            return Amount(with: blockchainNetwork.blockchain, type: .coin, value: decimal)
        case .token(let blockchainNetwork, _):
            return Amount(with: blockchainNetwork.blockchain, value: decimal)
        }
    }

    mutating func updateImageURL(_ imageURL: URL) {
        self.imageURL = imageURL
    }
}

// MARK: - Factory

extension ExchangeCurrency {
    static func daiToken(exchangeManager: ExchangeManager) -> ExchangeCurrency {
        let factory = ExchangeTokensFactory()

        do {
            return try factory.createToken(token: .dai(blockchain: exchangeManager.blockchainNetwork))
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    static func tetherToken(exchangeManager: ExchangeManager) -> ExchangeCurrency {
        let factory = ExchangeTokensFactory()

        do {
            return try factory.createToken(token: .tether(blockchain: exchangeManager.blockchainNetwork))
        } catch ExchangeTokensFactory.FactoryError.unavailableTokenForCurrentBlockchain {
            let token = try? factory.createToken(token: .dai(blockchain: exchangeManager.blockchainNetwork))
            if let token {
                return token
            }
            
            fatalError("Token is unavailable")
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

extension ExchangeCurrency {
    enum Currency {
        case coin(blockchainNetwork: BlockchainNetwork)
        case token(blockchainNetwork: BlockchainNetwork, contractAddress: String)

        var contractAddress: String {
            switch self {
            case .coin:
                return Constants.oneInchCoinContractAddress
            case .token(_, let contractAddress):
                return contractAddress
            }
        }
    }
}
