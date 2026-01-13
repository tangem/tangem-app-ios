//
//  TangemPayAccountBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemPay
import TangemVisa

final class TangemPayBuilder {
    private let userWalletId: UserWalletId
    private let keysRepository: KeysRepository
    private let authorizingInteractor: TangemPayAuthorizing
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

    private lazy var authorizationService = TangemPayAuthorizationServiceBuilder().build(
        customerWalletId: customerWalletId,
        tokens: tokens
    )

    private lazy var customerService = TangemPayCustomerServiceBuilder()
        .build(authorizationTokensHandler: authorizationService)

    private lazy var enrollmentStateFetcher = TangemPayEnrollmentStateFetcher(
        customerWalletId: customerWalletId,
        keysRepository: keysRepository,
        customerService: customerService
    )

    private lazy var orderStatusPollingService = TangemPayOrderStatusPollingService(
        customerService: customerService
    )

    private lazy var tokenBalancesRepository = CommonTokenBalancesRepository(userWalletId: userWalletId)

    private lazy var balancesService = CommonTangemPayBalanceService(
        customerService: customerService,
        tokenBalancesRepository: tokenBalancesRepository
    )

    private lazy var withdrawTransactionService = CommonTangemPayWithdrawTransactionService(
        customerService: customerService,
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
        authorizingInteractor: TangemPayAuthorizing,
        signer: any TangemSigner
    ) {
        self.userWalletId = userWalletId
        self.keysRepository = keysRepository
        self.authorizingInteractor = authorizingInteractor
        self.signer = signer
    }

    func buildTangemPayManager() -> TangemPayManager {
        TangemPayManager(
            customerWalletId: customerWalletId,
            authorizingInteractor: authorizingInteractor,
            authorizationService: authorizationService,
            customerService: customerService,
            enrollmentStateFetcher: enrollmentStateFetcher,
            orderStatusPollingService: orderStatusPollingService,
            tangemPayBuilder: self
        )
    }

    func buildTangemPayAccount(
        customerInfo: TangemPayCustomer,
        productInstance: TangemPayCustomer.ProductInstance
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
