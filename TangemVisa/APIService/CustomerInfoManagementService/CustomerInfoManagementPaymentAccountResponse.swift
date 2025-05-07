//
//  CustomerInfoManagementPaymentAccountResponse.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CustomerInfoManagementPaymentAccountResponse: Decodable {
    let id: String
    let customerWalletAddress: String
    let address: String
}
