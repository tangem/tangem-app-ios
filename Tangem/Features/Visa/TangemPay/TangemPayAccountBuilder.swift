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
    let userWalletId: UserWalletId
    let keysRepository: KeysRepository
    let signer: any TangemSigner
    let customerInfoManagementService: CustomerInfoManagementService

    func buildTangemPayAccount(
        customerInfo: VisaCustomerInfoResponse,
        productInstance: VisaCustomerInfoResponse.ProductInstance
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

        let expressCEXTransactionProcessor = TangemPayExpressCEXTransactionProcessor(
            withdrawTransactionService: withdrawTransactionService,
            walletPublicKey: TangemPayUtilities.getKey(from: keysRepository)
        )

        let withdrawAvailabilityProvider = TangemPayWithdrawAvailabilityProvider(
            withdrawTransactionService: withdrawTransactionService,
            tokenBalanceProvider: balancesService.availableBalanceProvider
        )

        let orderStatusPollingService = TangemPayOrderStatusPollingService(customerInfoManagementService: customerInfoManagementService)

        let mainHeaderBalanceProvider = TangemPayMainHeaderBalanceProvider(
            tangemPayTokenBalanceProvider: balancesService.fixedFiatTotalTokenBalanceProvider
        )

        return TangemPayAccount(
            customerInfo: customerInfo,
            productInstance: productInstance,
            customerInfoManagementService: customerInfoManagementService,
            balancesService: balancesService,
            withdrawTransactionService: withdrawTransactionService,
            expressCEXTransactionProcessor: expressCEXTransactionProcessor,
            withdrawAvailabilityProvider: withdrawAvailabilityProvider,
            orderStatusPollingService: orderStatusPollingService,
            mainHeaderBalanceProvider: mainHeaderBalanceProvider
        )
    }
}
