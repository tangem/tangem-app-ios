//
//  WCTransactionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

@MainActor
final class WCTransactionViewModel: ObservableObject & FloatingSheetContentViewModel {
    // MARK: Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: Published properties

    @Published private(set) var presentationState: PresentationState = .transactionDetails

    // MARK: Public properties

    let dAppData: WalletConnectDAppData
    let transactionData: WCHandleTransactionData

    var userWalletName: String {
        transactionData.userWalletModel.name
    }

    var primariActionButtonTitle: String {
        switch transactionData.method {
        case .sendTransaction:
            "Send"
        default:
            "Sign"
        }
    }

    init(
        dAppData: WalletConnectDAppData,
        transactionData: WCHandleTransactionData
    ) {
        self.dAppData = dAppData
        self.transactionData = transactionData
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .cancel:
            cancel()
        case .dismissTransactionView:
            cancel()
            floatingSheetPresenter.removeActiveSheet()
        case .returnTransactionDetails:
            presentationState = .transactionDetails
        case .sign:
            sign()
        case .showRequestData:
            showRequestData()
        }
    }
}

// MARK: - Action methods

private extension WCTransactionViewModel {
    func sign() {
        Task {
            do {
                presentationState = .signing
                try await transactionData.accept()
                presentationState = .transactionDetails
                floatingSheetPresenter.removeActiveSheet()
            } catch {
                presentationState = .transactionDetails
                makeWarningToast(with: error.localizedDescription)
            }
        }
    }

    func cancel() {
        Task {
            try? await transactionData.reject()
        }

        floatingSheetPresenter.removeActiveSheet()
    }

    func returnToTransactionDetails() {
        presentationState = .transactionDetails
    }

    func showRequestData() {
        let input = WCRequestDetailsInput(
            builder: .init(method: transactionData.method, source: transactionData.requestData),
            backAction: returnToTransactionDetails
        )

        presentationState = .requestData(input)
    }
}

// MARK: - Factory methods

extension WCTransactionViewModel {
    private func makeWarningToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }
}

extension WCTransactionViewModel {
    enum ViewAction {
        case dismissTransactionView
        case cancel
        case sign
        case returnTransactionDetails
        case showRequestData
    }

    enum PresentationState: Equatable {
        case signing
        case transactionDetails
        case requestData(WCRequestDetailsInput)
    }
}
