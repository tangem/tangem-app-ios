//
//  SwappingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

protocol SwappingRoutable: AnyObject {
    func presentSwappingTokenList(sourceCurrency: Currency)
    func presentSuccessView(inputModel: SwappingSuccessInputModel)
    func presentPermissionView(inputModel: SwappingPermissionInputModel, transactionSender: SwappingTransactionSender)
}
