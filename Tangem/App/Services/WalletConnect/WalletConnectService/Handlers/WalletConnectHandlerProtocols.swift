//
//  WalletConnectHandlerDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import WalletConnectSwift

protocol WalletConnectHandlerDelegate: AnyObject {
    func send(_ response: Response, for action: WalletConnectAction)
    func sendInvalid(_ request: Request)
    func sendReject(for request: Request, with error: Error, for action: WalletConnectAction)
    func sendUpdate(for session: Session, with walletInfo: Session.WalletInfo)
}

protocol WalletConnectHandlerDataSource: AnyObject {
    var cardModel: CardViewModel { get }
    func session(for request: Request) -> WalletConnectSession?
    func updateSession(_ session: WalletConnectSession)
}
