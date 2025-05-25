//
//  ReownWalletConnectDAppDataService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum ReownWalletKit.AutoNamespaces

final class ReownWalletConnectDAppDataService: WalletConnectDAppDataService {
    private let walletConnectService: any WCService

    init(walletConnectService: some WCService) {
        self.walletConnectService = walletConnectService
    }

    func getDAppDataAndProposal(
        for uri: WalletConnectRequestURI,
        source: Analytics.WalletConnectSessionSource
    ) async throws -> (WalletConnectDAppData, WalletConnectSessionProposal) {
        let reownSessionProposal = try await walletConnectService.openSession(with: uri, source: source)

        let dAppData = WalletConnectDAppData(
            name: reownSessionProposal.proposer.name,
            domain: try WalletConnectDAppDataMapper.mapDomainURL(from: reownSessionProposal),
            icon: WalletConnectDAppDataMapper.mapIconURL(from: reownSessionProposal)
        )

        let proposal = WalletConnectSessionProposal(
            id: reownSessionProposal.id,
            requiredNamespaces: WalletConnectSessionProposalMapper.mapToDomainNamespaces(from: reownSessionProposal.requiredNamespaces),
            optionalNamespaces: WalletConnectSessionProposalMapper.mapToOptionalDomainNamespaces(from: reownSessionProposal.optionalNamespaces),
            unsupportedBlockchainNames: WalletConnectSessionProposalMapper.mapUnsupportedBlockchainNames(from: reownSessionProposal),
            dAppConnectionRequestFactory: { [reownSessionProposal] selectedBlockchains, selectedUserWallet in
                let reownSessionNamespaces = try AutoNamespaces.build(
                    sessionProposal: reownSessionProposal,
                    chains: selectedBlockchains.compactMap(WalletConnectBlockchainMapper.mapFromDomain),
                    methods: WalletConnectSessionProposalMapper.mapAllMethods(from: reownSessionProposal),
                    events: WalletConnectSessionProposalMapper.mapAllEvents(from: reownSessionProposal),
                    accounts: selectedBlockchains.flatMap { WalletConnectAccountsMapper.map(from: $0, userWalletModel: selectedUserWallet) }
                )

                return WalletConnectDAppConnectionRequest(
                    proposalID: reownSessionProposal.id,
                    namespaces: WalletConnectSessionNamespaceMapper.mapToDomain(reownSessionNamespaces)
                )
            }
        )

        return (dAppData, proposal)
    }
}
