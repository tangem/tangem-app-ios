//
//  CommonWCService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class CommonWCService {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private let v2Service: WCServiceV2

    init() {
        v2Service = WCFactory().createWCService()
    }
}

extension CommonWCService: WCService {
    var canEstablishNewSessionPublisher: AnyPublisher<Bool, Never> {
        v2Service.canEstablishNewSessionPublisher.eraseToAnyPublisher()
    }

    var newSessions: AsyncStream<[WalletConnectSavedSession]> {
        get async {
            await v2Service.newSessions
        }
    }

    func initialize() {
        v2Service.initialize()
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

    func updateSelectedWalletId(_ userWalletId: String) {
        v2Service.updateConnectionData(userWalletId: userWalletId)
    }

    func updateSelectedNetworks(_ selectedNetworks: [BlockchainNetwork]) {
        v2Service.updateConnectionData(networks: selectedNetworks)
    }
}

// MARK: - IncomingActionResponder

extension CommonWCService: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .walletConnect(let uri) = action else {
            return false
        }

        openSession(with: uri, source: .deeplink)
        return true
    }
}
