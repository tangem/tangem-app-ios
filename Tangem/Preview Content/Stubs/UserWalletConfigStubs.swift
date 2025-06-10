//
//  UserWalletConfigStubs.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

enum UserWalletConfigStubs {
    static var walletV2Stub: UserWalletConfig = Wallet2Config(
        card: .init(card: CardMock.wallet2.card),
        isDemo: false
    )

    static var twinStub: UserWalletConfig = TwinConfig(
        card: .init(card: CardMock.twin.card),
        walletData: .init(blockchain: "BTC", token: nil),
        twinData: .init(series: .cb62, pairPublicKey: nil)
    )

    static var xrpNoteStub: UserWalletConfig = NoteConfig(
        card: .init(card: CardMock.xrpNote.card),
        noteData: .init(blockchain: "XRP", token: nil)
    )

    static var xlmBirdStub: UserWalletConfig = NoteConfig(
        card: .init(card: CardMock.xrpNote.card),
        noteData: .init(blockchain: "XLM", token: nil)
    )

    static var visaStub: UserWalletConfig = VisaConfig(
        card: .init(card: CardMock.visa.card),
        activationLocalState: .activated(authTokens: .init(accessToken: "", refreshToken: "", authorizationType: .cardId))
    )
}
