//
//  WalletConnectDAppDataMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import struct ReownWalletKit.Session

enum WalletConnectDAppDataMapper {
    static func mapDomainURL(from proposal: Session.Proposal) throws(WalletConnectDAppProposalLoadingError) -> URL {
        guard let domainURL = URL(string: proposal.proposer.url) else {
            throw WalletConnectDAppProposalLoadingError.invalidDomainURL(proposal.proposer.url)
        }

        return domainURL
    }

    static func mapIconURL(from proposal: Session.Proposal) -> URL? {
        // [REDACTED_TODO_COMMENT]
        proposal.proposer.icons.first(where: { $0.hasSuffix("png") }).flatMap(URL.init)
    }
}
