//
//  SingleTokenRoutableMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class SingleTokenRoutableMock: SingleTokenRoutable {
    var errorAlertPublisher: AnyPublisher<AlertBinder?, Never> { .just(output: nil) }

    func openReceive(walletModel: WalletModel) {}

    func openBuyCryptoIfPossible(walletModel: WalletModel) {}

    func openSend(walletModel: WalletModel) {}

    func openExchange(walletModel: WalletModel) {}

    func openSell(for walletModel: WalletModel) {}

    func openSendToSell(with request: SellCryptoRequest, for walletModel: WalletModel) {}

    func openExplorer(at url: URL, for walletModel: WalletModel) {}

    func openChooseAddress(from walletModel: WalletModel, callback: @escaping (BlockchainSdk.Address) -> Void) {}
}
