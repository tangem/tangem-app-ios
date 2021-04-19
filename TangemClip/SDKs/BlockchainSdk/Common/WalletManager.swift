//
//  Walletmanager.swift
//  blockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdkClips
import Combine

public enum WalletError: Error, LocalizedError {
    case noAccount(message: String)
    case failedToGetFee
    case failedToBuildTx
    case failedToParseNetworkResponse
    case failedToSendTx
    case failedToCalculateTxSize
    case failedToLoadTokenBalance(token: Token)
    
    public var errorDescription: String? {
        switch self {
        case .noAccount(let message):
            return message
        case .failedToGetFee:
            return "common_fee_error".localized
        case .failedToBuildTx:
            return "common_build_tx_error".localized
        case .failedToParseNetworkResponse:
            return "common_parse_network_response_error".localized
        case .failedToSendTx:
            return "common_send_tx_error".localized
        case .failedToCalculateTxSize:
            return "common_estimate_tx_size_error".localized
        case let .failedToLoadTokenBalance(token):
            return String(format: "common_failed_to_load_token_balance".localized, token.name)
        }
    }
    
}

public class WalletManager {
    public let cardId: String
    
    internal(set) public var cardTokens: [Token]
    @Published public var wallet: Wallet
    
    var defaultSourceAddress: String { wallet.address }
    var defaultChangeAddress: String { wallet.address }    
    var cancellable: Cancellable? = nil

    
    init(cardId: String, wallet: Wallet, cardTokens: [Token] = []) {
        self.cardId = cardId
        self.wallet = wallet
        self.cardTokens = cardTokens
    }
    
    public func update(completion: @escaping (Result<(), Error>)-> Void) {
        fatalError("You should override this method")
    }
    
    public func removeToken(_ token: Token) {
        cardTokens.removeAll(where: { $0 == token })
        wallet.remove(token: token)
    }
    
    public func addToken(_ token: Token) -> AnyPublisher<Amount, Error> {
        return Fail(error: BlockchainSdkError.notImplemented).eraseToAnyPublisher()
    }
}

public protocol TokenFinder {
    func findErc20Tokens(completion: @escaping (Result<Bool, Error>)-> Void)
}
