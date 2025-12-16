//
//  ReceiveMainViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit
import Foundation
import SwiftUI
import Combine
import TangemFoundation
import TangemUI
import BlockchainSdk
import TangemLocalization
import TangemAssets
import TangemAccessibilityIdentifiers

class ReceiveMainViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.overlayShareActivitiesPresenter) private var shareActivitiesPresenter: any ShareActivitiesPresenter
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - View State

    @Published private(set) var viewState: ViewState?

    // MARK: - Private Implementation

    private let options: Options

    private lazy var receiveFlowFactory: ReceiveFlowFactory = .init(
        flow: options.flow,
        tokenItem: options.tokenItem,
        addressTypesProvider: options.addressTypesProvider,
        coordinator: self,
        // [REDACTED_TODO_COMMENT]
        isYieldModuleActive: options.isYieldModuleActive
    )

    private let receiveTokenWithdrawNoticeInteractor = ReceiveTokenWithdrawNoticeInteractor()
    private let yieldModuleNotificationInteractor = YieldModuleNoticeInteractor()

    private lazy var selectorViewModel = receiveFlowFactory.makeSelectorReceiveAssetViewModel()

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
            viewState = .selector(viewModel: selectorViewModel)
        }
    }

    // MARK: - Private Implementation

    func getInitialViewState() -> ViewState? {
        if yieldModuleNotificationInteractor.shouldShowYieldModuleAlert(for: options.tokenItem) {
            receiveTokenWithdrawNoticeInteractor.markWithdrawalAlertShown(for: options.tokenItem)

            let vm = receiveFlowFactory.makeTokenAlertReceiveAssetViewModel(with: selectorViewModel)
            return .yieldTokenAlert(viewModel: vm)
        }

        if isNeedDisplayTokenAlert() {
            let viewModel = receiveFlowFactory.makeTokenAlertReceiveAssetViewModel(with: selectorViewModel)
            return .tokenAlert(viewModel: viewModel)
        }

        return .selector(viewModel: selectorViewModel)
    }

    func isNeedDisplayTokenAlert() -> Bool {
        if receiveTokenWithdrawNoticeInteractor.shouldShowWithdrawalAlert(for: options.tokenItem) {
            return true
        }

        return false
    }
}

// MARK: - Options

extension ReceiveMainViewModel {
    struct Options {
        let tokenItem: TokenItem
        let flow: ReceiveFlow
        let addressTypesProvider: ReceiveAddressTypesProvider
        // [REDACTED_TODO_COMMENT]
        let isYieldModuleActive: Bool
    }
}

// MARK: - ReceiveFlowCoordinator

extension ReceiveMainViewModel: ReceiveFlowCoordinator {
    func routeOnReceiveQR(with info: ReceiveAddressInfo) {
        let viewModel = receiveFlowFactory.makeQRCodeReceiveAssetViewModel(with: info)
        viewState = .qrCode(viewModel: viewModel)
    }

    func copyToClipboard(with address: String) {
        UIPasteboard.general.string = address

        Toast(
            view: SuccessToast(text: Localization.walletNotificationAddressCopied)
                .accessibilityIdentifier(ActionButtonsAccessibilityIdentifiers.addressCopiedToast)
        )
        .present(
            layout: .top(padding: 12),
            type: .temporary()
        )
    }

    func share(with address: String) {
        runTask(in: self) { @MainActor viewModel in
            viewModel.shareActivitiesPresenter.share(activityItems: [address])
        }
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
        case qrCode(viewModel: QRCodeReceiveAssetsViewModel)
        case yieldTokenAlert(viewModel: TokenAlertReceiveAssetsViewModel)

        // MARK: - Identifiable

        var id: String {
            switch self {
            case .selector:
                "selector"
            case .qrCode:
                "qrCode"
            case .tokenAlert:
                "tokenAlert"
            case .yieldTokenAlert:
                "yieldTokenAlert"
            }
        }

        var backgroundColor: Color {
            switch self {
            case .selector, .tokenAlert, .yieldTokenAlert:
                return Colors.Background.tertiary
            case .qrCode:
                return Colors.Background.primary
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
