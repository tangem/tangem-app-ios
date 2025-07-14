//
//  CommonWalletConnectService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class OldCommonWalletConnectService {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private var v2Service: OldWalletConnectV2Service

    init(v2Service: OldWalletConnectV2Service) {
        self.v2Service = v2Service
    }
}

extension OldCommonWalletConnectService: OldWalletConnectService {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        v2Service.canEstablishNewSessionPublisher.eraseToAnyPublisher()
    }

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await v2Service.newSessions
        }
    }

    func initialize(with infoProvider: OldWalletConnectUserWalletInfoProvider) {
        v2Service.initialize(with: infoProvider)
        incomingActionManager.becomeFirstResponder(self)
    }

    func reset() {
        incomingActionManager.resignFirstResponder(self)
    }

    func openSession(with uri: WalletConnectRequestURI, source: Analytics.WalletConnectSessionSource) {
        switch uri {
        case .v2(let v2URI):
            v2Service.openSession(with: v2URI, source: source)
        }
    }

    func disconnectSession(with id: Int) async {
        await v2Service.disconnectSession(with: id)
    }

    func disconnectAllSessionsForUserWallet(with userWalletId: String) {
        v2Service.disconnectAllSessionsForUserWallet(with: userWalletId)
    }
}

// MARK: - IncomingActionResponder

extension OldCommonWalletConnectService: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .walletConnect(let uri) = action else {
            return false
        }

        openSession(with: uri, source: .deeplink)
        return true
    }
}
