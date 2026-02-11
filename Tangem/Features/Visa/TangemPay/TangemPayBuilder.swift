//
//  TangemPayBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemPay

final class TangemPayBuilder {
    private let userWalletId: UserWalletId
    private let keysRepository: KeysRepository
    private let signer: any TangemSigner

    private var customerWalletId: String {
        userWalletId.stringValue
    }

    private var tokens: TangemPayAuthorizationTokens? {
        TangemPayUtilities.getCustomerWalletAddressAndAuthorizationTokens(
            customerWalletId: customerWalletId,
            keysRepository: keysRepository
        )?.tokens
    }

    private lazy var availabilityService = TangemPayAvailabilityServiceBuilder().build()

    private lazy var authorizationService = TangemPayAuthorizationServiceBuilder().build(customerWalletId: customerWalletId)

    private lazy var customerService = TangemPayCustomerInfoManagementServiceBuilder()
        .build(authorizationTokensHandler: authorizationService)

    private lazy var enrollmentStateFetcher = TangemPayEnrollmentStateFetcher(
        customerWalletId: customerWalletId,
        availabilityService: availabilityService,
        customerService: customerService
    )

    private lazy var orderStatusPollingService = TangemPayOrderStatusPollingService(
        customerService: customerService
    )

    private lazy var tokenBalancesRepository = CommonTokenBalancesRepository(userWalletId: userWalletId)

    private lazy var balancesService = CommonTangemPayBalanceService(
        customerInfoManagementService: customerService,
        tokenBalancesRepository: tokenBalancesRepository
    )

    private lazy var withdrawTransactionService = CommonTangemPayWithdrawTransactionService(
        customerInfoManagementService: customerService,
        fiatItem: TangemPayUtilities.fiatItem,
        signer: signer
    )

    private lazy var expressCEXTransactionProcessor = TangemPayExpressCEXTransactionProcessor(
        withdrawTransactionService: withdrawTransactionService,
        walletPublicKey: TangemPayUtilities.getKey(from: keysRepository)
    )

    private lazy var withdrawAvailabilityProvider = TangemPayWithdrawAvailabilityProvider(
        withdrawTransactionService: withdrawTransactionService,
        tokenBalanceProvider: balancesService.availableBalanceProvider
    )

    private lazy var mainHeaderBalanceProvider = TangemPayMainHeaderBalanceProvider(
        tangemPayTokenBalanceProvider: balancesService.fixedFiatTotalTokenBalanceProvider
    )

    init(
        userWalletId: UserWalletId,
        keysRepository: KeysRepository,
        signer: any TangemSigner
    ) {
        self.userWalletId = userWalletId
        self.keysRepository = keysRepository
        self.signer = signer
    }

    func buildTangemPayManager() -> TangemPayManager {
        CommonTangemPayManager(
            customerWalletId: customerWalletId,
            keysRepository: keysRepository,
            availabilityService: availabilityService,
            authorizationService: authorizationService,
            customerService: customerService,
            enrollmentStateFetcher: enrollmentStateFetcher,
            orderStatusPollingService: orderStatusPollingService,
            orderIdStorage: AppSettings.shared,
            paeraCustomerFlagRepository: AppSettings.shared,
            tangemPayAccountBuilder: self
        )
    }
}

extension TangemPayBuilder: TangemPayAccountBuilder {
    func makeTangemPayAccount(
        customerInfo: VisaCustomerInfoResponse,
        productInstance: VisaCustomerInfoResponse.ProductInstance
    ) -> TangemPayAccount {
        TangemPayAccount(
            customerInfo: customerInfo,
            productInstance: productInstance,
            customerService: customerService,
            balancesService: balancesService,
            withdrawTransactionService: withdrawTransactionService,
            expressCEXTransactionProcessor: expressCEXTransactionProcessor,
            withdrawAvailabilityProvider: withdrawAvailabilityProvider,
            orderStatusPollingService: orderStatusPollingService,
            mainHeaderBalanceProvider: mainHeaderBalanceProvider
        )
    }
}
