//
//  TangemPayCashbackDetailViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemVisa

@MainActor
final class TangemPayCashbackDetailViewModel: ObservableObject {
    @Published private(set) var state: TangemPayCashbackDetailState = .idle
    @Published var tiersViewData: TangemPayCashbackTiersViewData?
    @Published var accrualsViewData: TangemPayCashbackAccrualsViewData?

    @Injected(\.safariManager) private var safariManager: SafariManager

    private let cashbackSummary: TangemPayCashback.Summary
    private let userWalletId: UserWalletId
    private var cashbackDetails: TangemPayCashbackDetails?

    private let cashbackDetailsUseCase: TangemPayLoadCashbackDetailsUseCase
    private let viewDataFactory = TangemPayCashbackDetailViewDataFactory()

    var dismissHandler: (() -> Void)?

    init(
        summary: TangemPayCashback.Summary,
        userWalletId: UserWalletId,
        cashbackDetailsUseCase: TangemPayLoadCashbackDetailsUseCase
    ) {
        cashbackSummary = summary
        self.userWalletId = userWalletId
        self.cashbackDetailsUseCase = cashbackDetailsUseCase
    }

    func onAppear() {
        Analytics.log(.visaCashbackDetailsScreenOpened, contextParams: .userWallet(userWalletId))
        loadDetails()
    }

    func loadDetails() {
        runTask(in: self) { viewModel in
            await viewModel.load()
        }
    }

    func openTiersInfo() {
        guard let cashbackOnCards = cashbackDetails?.cashbackOnCards else {
            return
        }

        Analytics.log(.visaCashbackConditionsTileClicked, contextParams: .userWallet(userWalletId))
        tiersViewData = viewDataFactory.makeTiersViewData(
            cashbackOnCards: cashbackOnCards,
            payoutCurrency: cashbackSummary.payoutCurrency
        )
    }

    func closeTiersInfo() {
        tiersViewData = nil
    }

    func openAccrualsInfo() {
        Analytics.log(.visaCashbackAccrualsTileClicked, contextParams: .userWallet(userWalletId))
        accrualsViewData = viewDataFactory.makeAccrualsViewData(docs: cashbackDetails?.accrualsDocs ?? [])
    }

    func closeAccrualsInfo() {
        accrualsViewData = nil
    }

    func openDoc(_ doc: TangemPayCashbackAccrualsViewData.Doc) {
        Analytics.log(
            event: .visaCashbackTermsDocClicked,
            params: [.title: doc.title],
            contextParams: .userWallet(userWalletId)
        )
        safariManager.openURL(doc.url)
    }

    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func close() {
        dismissHandler?()
    }
}

// MARK: - Loading

private extension TangemPayCashbackDetailViewModel {
    func load() async {
        state = .loading

        do {
            let details = try await cashbackDetailsUseCase.loadCashbackDetails()
            try validate(details)

            let presentationData = viewDataFactory.make(details: details, summary: cashbackSummary)

            state = .loaded(presentationData)
            cashbackDetails = details
            logBannerIfNeeded(presentationData.banner)
        } catch {
            VisaLogger.error("Failed to load TangemPay cashback details", error: error)
            state = .failed
        }
    }

    func validate(_ details: TangemPayCashbackDetails) throws {
        let historyAmount = details.history.last?.amount

        guard historyAmount == cashbackSummary.confirmedAmount else {
            throw ValidationError.summaryOutOfSync(
                summaryAmount: cashbackSummary.confirmedAmount,
                historyAmount: historyAmount
            )
        }
    }
}

// MARK: - Analytics

private extension TangemPayCashbackDetailViewModel {
    func logBannerIfNeeded(_ banner: TangemPayCashbackDetailViewData.Banner?) {
        switch banner {
        case .deposit:
            Analytics.log(.visaCashbackUpcomingAccrualBannerShowed, contextParams: .userWallet(userWalletId))
        case .refund:
            Analytics.log(.visaCashbackNegativeBannerShowed, contextParams: .userWallet(userWalletId))
        case nil:
            break
        }
    }
}

// MARK: - Identifiable

extension TangemPayCashbackDetailViewModel: @MainActor Identifiable {
    var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
}

// MARK: - ValidationError

extension TangemPayCashbackDetailViewModel {
    enum ValidationError: Error {
        case summaryOutOfSync(summaryAmount: Decimal, historyAmount: Decimal?)
    }
}
