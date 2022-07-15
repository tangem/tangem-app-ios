//
//  TestnetTopupService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import UIKit

class TestnetBuyCryptoService {
    @Injected(\.transactionSigner) private var signer: TangemSigner

    private var bag: Set<AnyCancellable> = []

    func buyCrypto(_ target: CryptoToBuy) {
        switch target {
        case let .erc20Token(walletManager, token):
            buyErc20Token(walletManager: walletManager, token: token)
        }
    }

    private func buyErc20Token(walletManager: WalletManager, token: Token) {
        let amountToSend = Amount(with: walletManager.wallet.blockchain, value: 0)
        let destinationAddress = token.contractAddress

        var subs: AnyCancellable!
        subs = walletManager.getFee(amount: amountToSend, destination: destinationAddress)
            .flatMap { [unowned self] (fees: [Amount]) -> AnyPublisher<Void, Error> in
                let fee = fees[0]

                guard fee.value <= walletManager.wallet.amounts[.coin]?.value ?? 0 else {
                    return .anyFail(error: "testnet_error_not_enough_ether_message".localized)
                }

                guard let tx = try? walletManager.createTransaction(amount: amountToSend, fee: fee, destinationAddress: destinationAddress) else {
                    return .anyFail(error: "testnet_error_failed_create_tx".localized)
                }

                return walletManager.send(tx, signer: self.signer)
            }
            .sink { [unowned self] completion in
                if case let .failure(error) = completion {
                    print(error)
                    self.presentOnMain(error.alertController)
                } else {
                    self.presentOnMain(AlertBuilder.makeSuccessAlertController(message: "testnet_address_topuped".localized))
                }

                self.bag.remove(subs)
                subs = nil
            } receiveValue: {

            }

        bag.insert(subs)
    }

    private func presentOnMain(_ vc: UIViewController) {
        DispatchQueue.main.async {
            UIApplication.modalFromTop(vc)
        }
    }

}

extension TestnetBuyCryptoService {
    enum CryptoToBuy {
        case erc20Token(walletManager: WalletManager, token: Token)
    }
}
