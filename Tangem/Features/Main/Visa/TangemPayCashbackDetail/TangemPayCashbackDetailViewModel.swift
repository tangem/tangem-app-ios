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
    private var cashbackDetails: TangemPayCashbackDetails?

    private let cashbackDetailsUseCase: TangemPayLoadCashbackDetailsUseCase
    private let viewDataFactory = TangemPayCashbackDetailViewDataFactory()

    var dismissHandler: (() -> Void)?

    init(
        summary: TangemPayCashback.Summary,
        cashbackDetailsUseCase: TangemPayLoadCashbackDetailsUseCase
    ) {
        cashbackSummary = summary
        self.cashbackDetailsUseCase = cashbackDetailsUseCase
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

        tiersViewData = viewDataFactory.makeTiersViewData(cashbackOnCards: cashbackOnCards)
    }

    func closeTiersInfo() {
        tiersViewData = nil
    }

    func openAccrualsInfo() {
        accrualsViewData = viewDataFactory.makeAccrualsViewData(docs: cashbackDetails?.accrualsDocs ?? [])
    }

    func closeAccrualsInfo() {
        accrualsViewData = nil
    }

    func openDoc(_ url: URL) {
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
