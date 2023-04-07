//
//  SwappingManagerError.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum SwappingManagerError: Error {
    case walletAddressNotFound
    case destinationNotFound
    case amountNotFound
}
