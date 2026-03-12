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

    private lazy var services: PaymentAccountServicesProviding = CommonPaymentAccountServices(
        customerWalletId: customerWalletId,
        availabilityServiceBuilder: PaymentAccountAvailabilityServiceBuilder(),
        authorizationServiceBuilder: PaymentAccountAuthorizationServiceBuilder(),
        customerServiceBuilder: PaymentAccountCustomerInfoManagementServiceBuilder()
    )

    private lazy var tokenBalancesRepository = CommonTokenBalancesRepository(userWalletId: userWalletId)

    private lazy var balancesService = CommonTangemPayBalanceService(
        customerInfoManagementService: services.customerService,
        tokenBalancesRepository: tokenBalancesRepository
    )

    private lazy var withdrawTransactionService = CommonTangemPayWithdrawTransactionService(
        customerInfoManagementService: services.customerService,
        fiatItem: TangemPayUtilities.fiatItem,
        signer: signer
    )

    private lazy var expressCEXTransactionDispatcher = TangemPayExpressCEXTransactionDispatcher(
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
        TangemPayManager(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            availabilityService: services.availabilityService,
            authorizationService: services.authorizationService,
            customerService: services.customerService,
            enrollmentStateFetcher: services.enrollmentStateFetcher,
            orderStatusPollingService: services.orderStatusPollingService,
            orderIdStorage: AppSettings.shared,
            paeraCustomerFlagRepository: AppSettings.shared,
            cachedStateStorage: AppSettings.shared,
            paymentWalletFlagStorage: AppSettings.shared,
            tangemPayAccountBuilder: self
        )
    }
}

extension TangemPayBuilder: TangemPayAccountBuilder {
    func makeTangemPayAccount(
        customerInfo: VisaCustomerInfoResponse,
        productInstance: VisaCustomerInfoResponse.ProductInstance,
        account: (any TangemPayAccountModel)?
    ) -> TangemPayAccount {
        TangemPayAccount(
            userWalletId: userWalletId,
            customerInfo: customerInfo,
            productInstance: productInstance,
            customerService: services.customerService,
            balancesService: balancesService,
            withdrawTransactionService: withdrawTransactionService,
            expressCEXTransactionDispatcher: expressCEXTransactionDispatcher,
            withdrawAvailabilityProvider: withdrawAvailabilityProvider,
            orderStatusPollingService: services.orderStatusPollingService,
            mainHeaderBalanceProvider: mainHeaderBalanceProvider,
            account: account
        )
    }
}
