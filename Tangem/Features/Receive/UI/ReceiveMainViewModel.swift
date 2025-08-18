//
//  ReceiveMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit
import Foundation
import Combine
import TangemFoundation
import TangemUI
import BlockchainSdk
import TangemLocalization

class ReceiveMainViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - View State

    @Published private(set) var viewState: ViewState?

    // MARK: - Private Implementation

    private let options: Options

    private lazy var receiveFlowFactory: ReceiveFlowFactory = .init(
        flow: options.flow,
        tokenItem: options.tokenItem,
        addressInfos: options.addressInfos,
        coordinator: self
    )

    // MARK: - Helpers

    init(options: Options) {
        self.options = options
    }

    func start() {
        viewState = getInitialViewState()
    }

    // MARK: - Actions

    func onCloseTapAction() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func onBackTapAction() {
        if case .qrCode = viewState {
            let selectorViewModel = receiveFlowFactory.makeSelectorReceiveAssetViewModel()
            viewState = .selector(viewModel: selectorViewModel)
        }
    }

    // MARK: - Private Implementation

    func getInitialViewState() -> ViewState? {
        if isNeedDisplayTokenAlert() {
            let viewModel = receiveFlowFactory.makeTokenAlertReceiveAssetViewModel()
            return .tokenAlert(viewModel: viewModel)
        } else {
            let viewModel = receiveFlowFactory.makeSelectorReceiveAssetViewModel()
            return .selector(viewModel: viewModel)
        }
    }

    func isNeedDisplayTokenAlert() -> Bool {
        if options.tokenItem.isToken {
            // [REDACTED_TODO_COMMENT]
            return true
        }

        return false
    }
}

// MARK: - Options

extension ReceiveMainViewModel {
    struct Options {
        let tokenItem: TokenItem
        let addressInfos: [ReceiveAddressInfo]
        let flow: ReceiveFlow
    }
}

// MARK: - OnboardingReceiveDomainAssetsRoutable & SelectorReceiveDomainAssetsRoutable & SelectorReceiveAssetItemRoutable

extension ReceiveMainViewModel:
    TokenAlertReceiveAssetsRoutable, SelectorReceiveAssetItemRoutable {
    func routeOnReceiveQR(with info: ReceiveAddressInfo) {
        /*
         // [REDACTED_TODO_COMMENT]
         */
    }

    func copyToClipboard(with address: String) {
        UIPasteboard.general.string = address

        Toast(view: SuccessToast(text: Localization.walletNotificationAddressCopied))
            .present(
                layout: .top(padding: 12),
                type: .temporary()
            )
    }

    func routeOnSelectorReceiveAssets(with proxySelectorViewModel: SelectorReceiveAssetsViewModel) {
        viewState = .selector(viewModel: proxySelectorViewModel)
    }
}

// MARK: - FloatingSheetContentViewModel

extension ReceiveMainViewModel: FloatingSheetContentViewModel {}

// MARK: - ViewState

extension ReceiveMainViewModel {
    enum ViewState: Identifiable, Equatable {
        case selector(viewModel: SelectorReceiveAssetsViewModel)
        case tokenAlert(viewModel: TokenAlertReceiveAssetsViewModel)
        case qrCode

        // MARK: - Identifiable

        var id: String {
            switch self {
            case .selector:
                "selector"
            case .qrCode:
                "qrCode"
            case .tokenAlert:
                "tokenAlert"
            }
        }

        // MARK: - Equatable

        static func == (lhs: ReceiveMainViewModel.ViewState, rhs: ReceiveMainViewModel.ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.selector, .selector):
                return true
            case (.qrCode, .qrCode):
                return true
            case (.tokenAlert, .tokenAlert):
                return true
            default:
                return false
            }
        }
    }
}
