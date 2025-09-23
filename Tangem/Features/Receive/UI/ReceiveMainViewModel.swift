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
        yieldModuleData: options.yieldModuleData
    )

    private let receiveTokenWithdrawNoticeInteractor = ReceiveTokenWithdrawNoticeInteractor()
    private let yieldModuleNotificationInteractor = YieldModuleNoticeInteractor()

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
        if isNeedDisplayYieldAlert() {
            receiveTokenWithdrawNoticeInteractor.markWithdrawalAlertShown(for: options.tokenItem)

            let vm = receiveFlowFactory.makeTokenAlertReceiveAssetViewModel()
            return .yieldTokenAlert(viewModel: vm)
        }

        if isNeedDisplayTokenAlert() {
            let viewModel = receiveFlowFactory.makeTokenAlertReceiveAssetViewModel()
            return .tokenAlert(viewModel: viewModel)
        }

        let viewModel = receiveFlowFactory.makeSelectorReceiveAssetViewModel()
        return .selector(viewModel: viewModel)
    }

    private func isNeedDisplayYieldAlert() -> Bool {
        return false
        // [REDACTED_TODO_COMMENT]
//        yieldModuleNotificationInteractor.shouldShowYieldModuleAlert(for: options.tokenItem)
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
        let yieldModuleData: Bool?
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

        Toast(view: SuccessToast(text: Localization.walletNotificationAddressCopied))
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
