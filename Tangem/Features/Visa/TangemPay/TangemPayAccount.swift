//
//  TangemPayAccount.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemVisa
import TangemSdk
import TangemFoundation
import TangemAssets
import TangemLocalization

final class TangemPayAccount {
    var tangemPayCard: VisaCustomerInfoResponse.Card? {
        mapToCard(visaCustomerInfoResponse: customerInfo)
    }

    var tangemPayCardPublisher: AnyPublisher<VisaCustomerInfoResponse.Card?, Never> {
        $customerInfo
            .withWeakCaptureOf(self)
            .map { $0.mapToCard(visaCustomerInfoResponse: $1) }
            .eraseToAnyPublisher()
    }

    lazy var tangemPayExpressCEXTransactionProcessor = TangemPayExpressCEXTransactionProcessor(
        withdrawTransactionService: withdrawTransactionService,
        walletPublicKey: TangemPayUtilities.getKey(from: keysRepository)
    )

    // MARK: - Balances

    lazy var tangemPayTokenBalanceProvider: TokenBalanceProvider = TangemPayTokenBalanceProvider(
        walletModelId: .init(tokenItem: TangemPayUtilities.usdcTokenItem),
        tokenBalancesRepository: tokenBalancesRepository,
        balanceSubject: balanceSubject
    )

    lazy var tangemPayMainHeaderBalanceProvider: MainHeaderBalanceProvider = TangemPayMainHeaderBalanceProvider(
        tangemPayTokenBalanceProvider: tangemPayTokenBalanceProvider
    )

    lazy var tangemPayMainHeaderSubtitleProvider: MainHeaderSubtitleProvider = TangemPayMainHeaderSubtitleProvider(
        balanceSubject: balanceSubject
    )

    let customerInfoManagementService: any CustomerInfoManagementService
    let withdrawTransactionService: any TangemPayWithdrawTransactionService

    var depositAddress: String? {
        customerInfo?.depositAddress
    }

    var cardId: String? {
        customerInfo?.productInstance?.cardId
    }

    var cardNumberEnd: String? {
        customerInfo?.card?.cardNumberEnd
    }

    private let tokenBalancesRepository: any TokenBalancesRepository
    private let keysRepository: KeysRepository

    @Published var customerInfo: VisaCustomerInfoResponse? = nil

    private let balanceSubject = CurrentValueSubject<LoadingResult<TangemPayBalance, Error>, Never>(.loading)

    init(
        customerInfoManagementService: any CustomerInfoManagementService,
        tokenBalancesRepository: any TokenBalancesRepository,
        keysRepository: KeysRepository,
        withdrawTransactionService: any TangemPayWithdrawTransactionService
    ) {
        self.customerInfoManagementService = customerInfoManagementService
        self.keysRepository = keysRepository
        self.tokenBalancesRepository = tokenBalancesRepository
        self.withdrawTransactionService = withdrawTransactionService

        // No reference cycle here, self is stored as weak
        withdrawTransactionService.set(output: self)
    }

    @discardableResult
    func loadBalance() -> Task<Void, Never> {
        Task { await setupBalance() }
    }

    private func setupBalance() async {
        do {
            balanceSubject.send(.loading)
            let balance = try await customerInfoManagementService.getBalance()
            balanceSubject.send(.success(balance))
        } catch {
            balanceSubject.send(.failure(error))
        }
    }

    private func mapToCard(
        visaCustomerInfoResponse: VisaCustomerInfoResponse?
    ) -> VisaCustomerInfoResponse.Card? {
        guard let card = customerInfo?.card,
              let productInstance = customerInfo?.productInstance,
              [.active, .blocked].contains(productInstance.status) else {
            return nil
        }

        return card
    }
}

// MARK: - TangemPayWithdrawTransactionServiceOutput

extension TangemPayAccount: TangemPayWithdrawTransactionServiceOutput {
    func withdrawTransactionDidSent() {
        Task {
            // Update balance after withdraw with some delay
            try await Task.sleep(seconds: 5)
            await setupBalance()
        }
    }
}

// MARK: - MainHeaderSupplementInfoProvider

extension TangemPayAccount: MainHeaderSupplementInfoProvider {
    var name: String {
        Localization.tangempayTitle
    }

    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: nil)
    }

    var updatePublisher: AnyPublisher<UpdateResult, Never> {
        .empty
    }
}

extension TangemPayAccount: Equatable {
    static func == (lhs: TangemPayAccount, rhs: TangemPayAccount) -> Bool {
        lhs.customerInfo == rhs.customerInfo
    }
}
