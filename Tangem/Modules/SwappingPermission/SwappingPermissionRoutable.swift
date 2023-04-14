//
//  SwappingPermissionRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSwapping

protocol SwappingPermissionRoutable: AnyObject {
    func didSendApproveTransaction(transactionData: SwappingTransactionData)
    func userDidCancel()
}
