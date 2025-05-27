//
//  WCTransactionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUICore
import struct SwiftUI.Animation
import TangemUI

@MainActor
final class WCTransactionViewModel: ObservableObject & FloatingSheetContentViewModel {
    // MARK: Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: Published properties

    @Published private(set) var presentationState: PresentationState = .transactionDetails

    // MARK: Public properties

    let id = UUID().uuidString
    let dappInfo: WalletConnectSavedSession.DAppInfo
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

    private let contentSwitchAnimation: Animation = .timingCurve(0.69, 0.07, 0.27, 0.95, duration: 0.5)

    init(
        dappInfo: WalletConnectSavedSession.DAppInfo,
        transactionData: WCHandleTransactionData
    ) {
        self.dappInfo = dappInfo
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
        withAnimation(contentSwitchAnimation) {
            presentationState = .transactionDetails
        }
    }

    func showRequestData() {
        let input = WCRequestDetailsInput(
            builder: .init(method: transactionData.method, source: transactionData.requestData),
            backAction: returnToTransactionDetails
        )

        withAnimation(contentSwitchAnimation) {
            presentationState = .requestData(input)
        }
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
