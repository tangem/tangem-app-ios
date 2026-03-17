//
//  MainQRScanFlowCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemUIUtils

final class MainQRScanFlowCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    private let scanResolutionQueue = DispatchQueue(
        label: "com.tangem.mainqrscan.resolve",
        qos: .userInitiated
    )

    // MARK: - State

    @Published var alert: AlertBinder?

    // MARK: - Child coordinators

    @Published var qrScanCoordinator: MainQRScanCoordinator?

    // MARK: - Private

    private lazy var flowHandler = MainQRScanFlowHandler(userWalletRepository: userWalletRepository)

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        Task { @MainActor in
            openQRScanner()
        }
    }

    // MARK: - Flow Navigation

    @MainActor
    private func openQRScanner() {
        let dismissAction: Action<String?> = { [weak self] scannedCode in
            guard let self else { return }
            guard let scannedCode else {
                MainQRScanLogger.debug(MainQRScanLoggerStrings.qrScannerClosedByUser)
                qrScanCoordinator = nil
                self.dismissAction(())
                return
            }

            MainQRScanLogger.debug(MainQRScanLoggerStrings.flowCoordinatorReceivedScanResult)
            handleScannedCode(scannedCode)
        }

        let coordinator = MainQRScanCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init())
        qrScanCoordinator = coordinator
    }

    // MARK: - Result Handling

    @MainActor
    private func handleScannedCode(_ code: String) {
        let flowHandlerSnapshot = flowHandler
        let context = flowHandlerSnapshot.makeContext()

        scanResolutionQueue.async { [weak self] in
            guard let self else {
                return
            }

            let action = flowHandlerSnapshot.resolve(scannedCode: code, context: context)

            Task { @MainActor [weak self] in
                guard
                    let self,
                    qrScanCoordinator != nil
                else {
                    return
                }

                MainQRScanLogger.debug(MainQRScanLoggerStrings.flowCoordinatorResolvedAction(action.debugName))
                route(action)
            }
        }
    }

    @MainActor
    private func route(_ action: MainQRScanAction) {
        switch action {
        case .walletConnect(let uri):
            handleWalletConnect(uri: uri)
        case .paymentSingle(let request):
            handlePaymentSingle(request: request)
        case .paymentMultiple(let request):
            handlePaymentMultiple(request: request)
        case .addressSingle(let request):
            handleAddressSingle(request: request)
        case .addressMultiple(let request):
            handleAddressMultiple(request: request)
        case .showNoSupportedTokens:
            showNoSupportedTokensAlert()
        case .showUnrecognized:
            showUnrecognizedAlert()
        }
    }

    @MainActor
    private func handleWalletConnect(uri: WalletConnectRequestURI) {
        guard let viewModel = WalletConnectModuleFactory.makeDAppConnectionViewModel(
            forURI: uri,
            source: .qrCode
        ) else {
            showUnrecognizedAlert()
            return
        }

        viewModel.loadDAppProposal()
        qrScanCoordinator = nil
        floatingSheetPresenter.enqueue(sheet: viewModel)
        dismissAction(())
    }

    @MainActor
    private func handlePaymentSingle(request: MainQRResolvedPaymentRequest) {
        _ = request
        showUnsupportedRecognizedRouteAlert()
    }

    @MainActor
    private func handlePaymentMultiple(request: MainQRResolvedPaymentRequest) {
        _ = request
        showUnsupportedRecognizedRouteAlert()
    }

    @MainActor
    private func handleAddressSingle(request: MainQRAddressRequest) {
        _ = request
        showUnsupportedRecognizedRouteAlert()
    }

    @MainActor
    private func handleAddressMultiple(request: MainQRAddressRequest) {
        _ = request
        showUnsupportedRecognizedRouteAlert()
    }

    private func showUnrecognizedAlert() {
        alert = AlertBinder(
            alert: Alert(
                title: Text("Unrecognized QR Code"),
                message: Text("Sorry, this QR code could not be recognized."),
                dismissButton: .default(Text("OK"), action: { [weak self] in
                    self?.rearmScanner()
                })
            )
        )
    }

    private func showNoSupportedTokensAlert() {
        alert = AlertBinder(
            alert: Alert(
                title: Text("No supported tokens found"),
                message: Text("This network isn't supported by any of your added tokens. Add a supported token to send crypto."),
                dismissButton: .default(Text("OK"), action: { [weak self] in
                    self?.rearmScanner()
                })
            )
        )
    }

    private func showUnsupportedRecognizedRouteAlert() {
        alert = AlertBinder(
            alert: Alert(
                title: Text("QR code type is not supported yet"),
                message: Text("This QR code was recognized, but this operation is not supported yet."),
                dismissButton: .default(Text("OK"), action: { [weak self] in
                    self?.rearmScanner()
                })
            )
        )
    }

    private func rearmScanner() {
        Task { @MainActor [weak self] in
            self?.qrScanCoordinator?.rearmScanner()
        }
    }
}

// MARK: - Options

extension MainQRScanFlowCoordinator {
    struct Options {}
}
