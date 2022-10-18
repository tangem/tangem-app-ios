//
//  SaltPayRegistratorProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class SaltPayRegistratorProvider: SaltPayRegistratorProviding {
    var registrator: SaltPayRegistrator?

    func initialize(cardId: String, walletPublicKey: Data, cardPublicKey: Data) throws {
        let wmFactory = WalletManagerFactoryProvider().factory

        let gnosis = try GnosisRegistrator(settings: .main,
                                           walletPublicKey: walletPublicKey,
                                           factory: wmFactory)

        let registrator = SaltPayRegistrator(cardId: cardId,
                                             cardPublicKey: cardPublicKey,
                                             walletPublicKey: walletPublicKey,
                                             gnosis: gnosis)

        self.registrator = registrator
    }

    func reset() {
        registrator = nil
    }
}
