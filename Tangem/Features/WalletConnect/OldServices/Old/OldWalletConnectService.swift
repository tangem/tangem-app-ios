//
//  WalletConnectService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol OldWalletConnectService {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> { get }
    var newSessions: AsyncStream<[WalletConnectSavedSession]> { get async }

    func initialize(with infoProvider: OldWalletConnectUserWalletInfoProvider)
    func reset()
    func openSession(with uri: WalletConnectRequestURI, source: Analytics.WalletConnectSessionSource)
    func disconnectSession(with id: Int) async
    func disconnectAllSessionsForUserWallet(with userWalletId: String)
}
