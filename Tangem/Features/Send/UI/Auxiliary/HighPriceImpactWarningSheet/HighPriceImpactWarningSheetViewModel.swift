//
//  HighPriceImpactWarningSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemUI

class HighPriceImpactWarningSheetViewModel: FloatingSheetContentViewModel, ObservableObject {
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: any FloatingSheetPresenter

    @Published var isActionProcessing: Bool = false

    var subtitle: String {
        highPriceImpact.infoMessage
    }

    let mainButtonIcon: MainButton.Icon?

    private let highPriceImpact: HighPriceImpactCalculator.Result
    private var continuation: CheckedContinuation<UserDecision, Never>?

    init(highPriceImpact: HighPriceImpactCalculator.Result, tangemIconProvider: TangemIconProvider) {
        self.highPriceImpact = highPriceImpact
        mainButtonIcon = tangemIconProvider.getMainButtonIcon()
    }

    func cancel() {
        continuation?.resume(returning: .cancel)
    }

    func sendAnyway() {
        continuation?.resume(returning: .sendAnyway)
    }

    func process(send: () async throws -> TransactionDispatcherResult) async throws -> TransactionDispatcherResult {
        let decision = await withCheckedContinuation { continuation in
            self.continuation = continuation
        }

        // In any case we dismiss the sheet
        defer { dismiss() }

        switch decision {
        case .sendAnyway:
            await runOnMain { isActionProcessing = true }
            let dispatcherResult = try await send()
            await runOnMain { isActionProcessing = false }
            return dispatcherResult
        case .cancel:
            throw TransactionDispatcherResult.Error.userCancelled
        }
    }

    private func dismiss() {
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }
}

extension HighPriceImpactWarningSheetViewModel {
    enum UserDecision {
        case sendAnyway
        case cancel
    }
}
