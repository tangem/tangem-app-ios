//
//  JointAccountConfirmSharedAddressRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol JointAccountConfirmSharedAddressRoutable: AnyObject {
    func shareSharedAddress(_ address: String)
    func openSharedAddressMismatch()
    func didConfirmSharedAddress()
}
