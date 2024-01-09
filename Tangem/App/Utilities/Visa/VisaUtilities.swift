//
//  VisaUtilities.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct VisaUtilities {
    var visaToken: Token {
        testnetUSDTtoken
    }

    func getWalletManager(keys: [CardDTO.Wallet]) throws -> WalletManager {
        let blockchain = Blockchain.polygon(testnet: true)

        guard let walletPublicKey = keys.first(where: { $0.curve == blockchain.curve })?.publicKey else {
            throw CommonError.noData
        }

        let factory = WalletManagerFactoryProvider().factory
        let publicKey = Wallet.PublicKey(seedKey: walletPublicKey, derivationType: .none)
        let walletManager = try factory.makeWalletManager(blockchain: blockchain, publicKey: publicKey)

        walletManager.addTokens([visaToken])
        return walletManager
    }

    func getVisaWalletModel(for userWalletModel: UserWalletModel) -> WalletModel {
        guard
            let walletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
                $0.tokenItem.token == visaToken
            })
        else {
            fatalError("Visa failed to find mandatory Visa wallet model")
        }

        return walletModel
    }
}

extension VisaUtilities {
    enum VisaError: Error {
        case failedToFindMandatoryWalletModel
    }
}

private extension VisaUtilities {
    private var testnetUSDTtoken: Token {
        .init(
            name: "Tether",
            symbol: "USDT",
            contractAddress: "0x1A826Dfe31421151b3E7F2e4887a00070999150f",
            decimalCount: 18,
            id: "tether"
        )
    }
}
