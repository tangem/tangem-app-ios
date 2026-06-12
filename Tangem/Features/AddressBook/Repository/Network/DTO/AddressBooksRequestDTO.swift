//
//  AddressBooksRequestDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Body of `POST /address-books` — loads the books for several wallets at once. Passing the known
/// `etags` lets the backend omit unchanged books from the response.
struct AddressBooksRequestDTO: Encodable {
    let walletIds: [String]
    let etags: [String: String]?
}
