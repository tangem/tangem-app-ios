//
//  SwappingPermissionRoutableMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping

class SwappingPermissionRoutableMock: SwappingPermissionRoutable {
    func didSendApproveTransaction(transactionData: TangemSwapping.SwappingTransactionData) {}
    func userDidCancel() {}
}

class SwappingApproveRoutableMock: SwappingApproveRoutable {
    func didSendApproveTransaction(transactionData: TangemSwapping.SwappingTransactionData) {}
    func userDidCancel() {}
}
