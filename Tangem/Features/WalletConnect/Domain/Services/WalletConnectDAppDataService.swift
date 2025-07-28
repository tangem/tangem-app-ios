//
//  WalletConnectDAppDataService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol WalletConnectDAppDataService {
    func getDAppDataAndProposal(
        for uri: WalletConnectRequestURI
    ) async throws(WalletConnectDAppProposalLoadingError) -> (WalletConnectDAppData, WalletConnectDAppSessionProposal)
}
