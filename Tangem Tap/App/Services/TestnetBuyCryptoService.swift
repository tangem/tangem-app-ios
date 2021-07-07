//
//  TestnetTopupService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import UIKit

class TestnetBuyCryptoService {
    enum CryptoToBuy {
        case erc20Token(walletManager: WalletManager, token: Token)
    }
    
    static var signer: TransactionSigner!
    
    private static var bag: Set<AnyCancellable> = []
    
    static func buyCrypto(_ target: CryptoToBuy) {
        switch target {
        case let .erc20Token(walletManager, token):
            buyErc20Token(walletManager: walletManager, token: token)
        }
    }
    
    private static func buyErc20Token(walletManager: WalletManager, token: Token) {
        guard let transactionSender = walletManager as? TransactionSender else {
            return
        }
        
        let amountToSend = Amount(with: walletManager.wallet.blockchain, value: 0)
        let destinationAddress = token.contractAddress
        
        var subs: AnyCancellable!
        subs = transactionSender.getFee(amount: amountToSend, destination: destinationAddress)
            .flatMap { (fees: [Amount]) -> AnyPublisher<Void, Error> in
                let fee = fees[0]
                
                guard fee.value <= walletManager.wallet.amounts[.coin]?.value ?? 0 else {
                    return .anyFail(error: "testnet_error_not_enough_ether_message".localized)
                }
                
                guard
                    case let txResult = walletManager.createTransaction(amount: amountToSend, fee: fee, destinationAddress: destinationAddress),
                    case let .success(tx) = txResult  else {
                    return .anyFail(error: "testnet_error_failed_create_tx".localized)
                }
                
                return transactionSender.send(tx, signer: signer)
            }
            .sink { completion in
                if case let .failure(error) = completion {
                    print(error)
                    presentOnMain(error.alertController)
                } else {
                    presentOnMain(AlertBuilder.makeSuccessAlertController(message: "testnet_address_topuped".localized))
                }
                bag.remove(subs)
                subs = nil
            } receiveValue: {
                
            }
        bag.insert(subs)
    }
    
    private static func presentOnMain(_ vc: UIViewController) {
        DispatchQueue.main.async {
            UIApplication.modalFromTop(vc)
        }
    }
    
}
