//
//  SwappingPermissionRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange

protocol SwappingPermissionRoutable: AnyObject {
    func didSendApproveTransaction(transactionInfo: ExchangeTransactionDataModel)
    func userDidCancel()
}
