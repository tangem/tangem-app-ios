//
//  FakeWalletManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk

// final class FakeWalletManager: WalletManager {
//    [REDACTED_USERNAME] var wallet: Wallet
//
//    var cardTokens: [Token]
//
//    var outputsCount: Int?
//    var allowsFeeSelection: Bool
//
//    var walletPublisher: Published<Wallet>.Publisher { $wallet }
//    var currentHost: String { "tangem.com" }
//
//    private var lastTxSended: Bool = true
//
//    init(blockchain: Blockchain, derivationPath: DerivationPath?) {}
//
//    init(cardTokens: [Token], wallet: Wallet, outputsCount: Int? = nil, allowsFeeSelection: Bool) {
//        self.cardTokens = cardTokens
//        self.wallet = wallet
//        self.outputsCount = outputsCount
//        self.allowsFeeSelection = allowsFeeSelection
//    }
//
//    func update(completion: @escaping (Result<Void, Error>) -> Void) {
//        <#code#>
//    }
//
//    func updatePublisher() -> AnyPublisher<Wallet, Error> {
//        <#code#>
//    }
//
//    func removeToken(_ token: Token) {
//        <#code#>
//    }
//
//    func addToken(_ token: Token) {
//        cardTokens.append(token)
//    }
//
//    func addTokens(_ tokens: [Token]) {
//        cardTokens.append(contentsOf: tokens)
//    }
//
//    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
//        let delay: TimeInterval = 5
//
//        if lastTxSended {
//            return .anyFail(error: "Failed to send transaction")
//                .delay(for: delay, scheduler: DispatchQueue.main)
//                .eraseToAnyPublisher()
//        }
//        return .justWithError(output: TransactionSendResult(hash: "0x0000"))
//    }
//
//    func validate(fee: Fee) throws {
//        <#code#>
//    }
//
//    func validate(amount: Amount) throws {
//        <#code#>
//    }
//
//    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
//        <#code#>
//    }
// }
