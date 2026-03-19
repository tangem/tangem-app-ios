//
//  MainQRScanFlowCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI
import TangemLocalization
import TangemUIUtils

final class MainQRScanFlowCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    // MARK: - State

    @Published var viewState: ViewState = .scanner
    @Published var alert: AlertBinder?

    // MARK: - Child coordinators

    @Published var qrScanCoordinator: MainQRScanCoordinator?
    @Published var sendCoordinator: SendCoordinator?

    // MARK: - Private

    private lazy var walletModelMatcher = MainQRWalletModelMatcher(userWalletRepository: userWalletRepository)
    private let routeResolver = MainQRScanRouteResolver()
    private let sendParametersFactory = MainQRSendParametersFactory()

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
                closeScanner()
                self.dismissAction(())
                return
            }

            handleScannedCode(scannedCode)
        }

        let coordinator = MainQRScanCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init())
        qrScanCoordinator = coordinator
        viewState = .scanner
    }

    // MARK: - Result Handling

    @MainActor
    private func handleScannedCode(_ code: String) {
        let context = walletModelMatcher.collectContext()
        let resolver = routeResolver

        Task { [weak self] in
            let action = await Task.detached(priority: .userInitiated) {
                resolver.resolve(
                    scannedCode: code,
                    availableBlockchains: context.allBlockchains,
                    availableTokenItems: context.allTokenItems
                )
            }.value

            guard let self, qrScanCoordinator != nil else { return }

            route(action, allMatches: context.allMatches)
        }
    }

    @MainActor
    private func route(_ action: MainQRScanAction, allMatches: [MainQRWalletModelMatch]) {
        switch action {
        case .walletConnect(let uri):
            handleWalletConnect(uri: uri)

        case .payment(let request):
            let sendParameters = sendParametersFactory.makeSendParameters(
                destination: request.request.destinationAddress,
                amount: request.request.amount,
                tag: request.request.memo
            )
            let matches = walletModelMatcher.filterMatches(allMatches, for: request.matchingTokenItems)

            openSendOrStub(
                matches: matches,
                sendParameters: sendParameters,
                noSupportedTokensContext: .payment(request.request)
            )

        case .address(let request):
            let sendParameters = sendParametersFactory.makeSendParameters(
                destination: request.destinationAddress,
                amount: nil,
                tag: nil
            )
            let matches = walletModelMatcher.filterMatches(allMatches, for: request.matchingBlockchains)

            openSendOrStub(
                matches: matches,
                sendParameters: sendParameters,
                noSupportedTokensContext: nil
            )

        case .showNoSupportedTokens(let context):
            showNoSupportedTokensAlert(context: context)

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
            MainQRScanLogger.warning(MainQRScanLoggerStrings.walletConnectViewModelCreationFailed)
            showUnrecognizedAlert()
            return
        }

        viewModel.loadDAppProposal()
        closeScanner()
        floatingSheetPresenter.enqueue(sheet: viewModel)
        dismissAction(())
    }

    @MainActor
    private func openSendOrStub(
        matches: [MainQRWalletModelMatch],
        sendParameters: PredefinedSendParameters,
        noSupportedTokensContext: MainQRNoSupportedTokensContext?
    ) {
        switch matches.count {
        case 0:
            showNoSupportedTokensAlert(context: noSupportedTokensContext)
        case 1:
            guard let match = matches.first else {
                showNoSupportedTokensAlert(context: noSupportedTokensContext)
                return
            }

            openSend(with: match, parameters: sendParameters)
        default:
            // [REDACTED_TODO_COMMENT]
            showMultipleMatchesStubAlert()
        }
    }

    @MainActor
    private func openSend(with match: MainQRWalletModelMatch, parameters: PredefinedSendParameters) {
        let sourceTokenFactory = SendWithSwapTokenFactory(
            userWalletInfo: match.userWalletInfo,
            walletModel: match.walletModel
        )
        let sourceToken = sourceTokenFactory.makeWithSwapToken()
        let resolvedParameters = sendParametersFactory.resolveSendParameters(
            parameters,
            sourceToken: sourceToken
        )

        let options = SendCoordinator.Options(
            type: .send(sourceToken, parameters: resolvedParameters),
            source: .qrScan
        )

        let coordinator = SendCoordinator(
            dismissAction: { [weak self] _ in
                self?.sendCoordinator = nil
                self?.dismissAction(())
            },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: options)

        sendCoordinator = coordinator
        viewState = .send
        closeScanner()
    }

    @MainActor
    private func showUnrecognizedAlert() {
        turnOffScannerFlashIfNeeded()
        alert = AlertBinder(
            alert: Alert(
                title: Text(Localization.qrScannerErrorUnrecognizedTitle),
                message: Text(Localization.qrScannerErrorUnrecognizedMessage),
                dismissButton: .default(Text(Localization.commonOk), action: { [weak self] in
                    self?.rearmScanner()
                })
            )
        )
    }

    @MainActor
    private func showNoSupportedTokensAlert(context: MainQRNoSupportedTokensContext? = nil) {
        turnOffScannerFlashIfNeeded()
        alert = AlertBinder(
            alert: Alert(
                title: Text(Localization.qrScannerErrorUnsupportedNetworkTitle),
                message: Text(Localization.qrScannerErrorUnsupportedNetworkMessage),
                dismissButton: .default(Text(Localization.commonOk), action: { [weak self] in
                    self?.rearmScanner()
                })
            )
        )
    }

    @MainActor
    private func showMultipleMatchesStubAlert() {
        turnOffScannerFlashIfNeeded()
        alert = AlertBinder(
            alert: Alert(
                title: Text(Localization.qrScannerErrorUnsupportedNetworkTitle),
                // [REDACTED_TODO_COMMENT]
                message: Text(Localization.qrScannerErrorUnsupportedNetworkMessage),
                dismissButton: .default(Text(Localization.commonOk), action: { [weak self] in
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

    @MainActor
    private func closeScanner() {
        turnOffScannerFlashIfNeeded()
        qrScanCoordinator = nil
    }

    @MainActor
    private func turnOffScannerFlashIfNeeded() {
        qrScanCoordinator?.turnOffFlashIfNeeded()
    }
}

// MARK: - Options

extension MainQRScanFlowCoordinator {
    struct Options {}

    enum ViewState: Identifiable {
        case scanner
        case send

        var id: String {
            switch self {
            case .scanner:
                return "scanner"
            case .send:
                return "send"
            }
        }
    }
}
