//
//  P2PDTO+AccountsList.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension P2PDTO {
    enum AccountsList {
        typealias Response = GenericResponse<AccountsListInfo>

        struct Request: Encodable {
            let delegatorAddresses: [String]
        }

        struct AccountsListInfo: Decodable {
            let list: [AccountListItem]
        }

        struct AccountListItem: Decodable {
            let delegatorAddress: String
            let account: AccountSummary.AccountSummaryInfo?
            let error: APIError?
        }
    }
}
