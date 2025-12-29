//
//  TangemPayAccountBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemVisa

struct TangemPayAccountBuilder {
    func build(
        customerWalletAddress: String,
        customerInfo: VisaCustomerInfoResponse,
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        signer: any TangemSigner,
        customerInfoManagementService: CustomerInfoManagementService
    ) -> TangemPayAccount {
        let tokenBalancesRepository = CommonTokenBalancesRepository(userWalletId: userWalletId)

        let balancesService = CommonTangemPayBalanceService(
            customerInfoManagementService: customerInfoManagementService,
            tokenBalancesRepository: tokenBalancesRepository
        )

        let withdrawTransactionService = CommonTangemPayWithdrawTransactionService(
            customerInfoManagementService: customerInfoManagementService,
            fiatItem: TangemPayUtilities.fiatItem,
            signer: signer
        )

        return TangemPayAccount(
            customerWalletId: userWalletId.stringValue,
            customerWalletAddress: customerWalletAddress,
            customerInfo: customerInfo,
            keysRepository: keysRepository,
            customerInfoManagementService: customerInfoManagementService,
            balancesService: balancesService,
            withdrawTransactionService: withdrawTransactionService
        )
    }
}
