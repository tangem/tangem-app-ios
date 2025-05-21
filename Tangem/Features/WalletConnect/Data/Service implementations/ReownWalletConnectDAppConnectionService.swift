//
//  ReownWalletConnectDAppConnectionService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import ReownWalletKit

final class ReownWalletConnectDAppConnectionService: WalletConnectDAppConnectionService {
    private let walletConnectService: any WCService

    init(walletConnectService: some WCService) {
        self.walletConnectService = walletConnectService
    }

    func connectDApp(with request: WalletConnectDAppConnectionRequest) async throws {
//        do {
//            let sessionNamespaces = try AutoNamespaces.build(
//                sessionProposal: Session.Proposal,
//                chains: [Blockchain("eip155:1")!],
//                methods: [""],
//                events: [""],
//                accounts: [
//                    .init(blockchain: Blockchain("eip155:1")!, accountAddress: ""),
//                ]
//            )
//
//            try await walletConnectService.acceptSessionProposal(with: request.proposalID, namespaces: sessionNamespaces)
//        } catch {
//            print(error)
//            throw error
//        }
    }

    func disconnectDApp(with request: WalletConnectDAppConnectionRequest) async throws {}
}
