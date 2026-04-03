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
import TangemAccounts
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
    @Published var isProcessing = false

    // MARK: - Child coordinators

    @Published var qrScanCoordinator: MainQRScanCoordinator?
    @Published var sendCoordinator: SendCoordinator?

    // MARK: - Child view models

    @Published var tokenSelectorViewModel: MainQRScanTokenSelectorViewModel?

    // MARK: - Private

    private lazy var walletModelMatcher = MainQRWalletModelMatcher(userWalletRepository: userWalletRepository)
    private let routeResolver = MainQRScanRouteResolver()
    private let sendParametersFactory = MainQRSendParametersFactory()
    private let alertFactory = MainQRScanAlertFactory()

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
        isProcessing = true

        Task { [weak self] in
            guard let self else { return }

            let routeAction = await resolveRouteAction(code: code)

            guard qrScanCoordinator != nil else { return }
            route(routeAction)
        }
    }

    @MainActor
    private func route(_ action: ResolvedRouteAction) {
        isProcessing = false

        switch action {
        case .walletConnect(let uri):
            handleWalletConnect(uri: uri)

        case .payment(let request, let allMatches):
            if !request.request.unknownParameters.isEmpty {
                showUnknownParametersAlert(request: request, allMatches: allMatches)
                return
            }

            handlePayment(request: request, allMatches: allMatches)

        case .address(let matchResult, let sendParameters, let filter):
            openSendOrSelector(
                matches: matchResult.filtered,
                unfilteredMatchCount: matchResult.unfilteredCount,
                sendParameters: sendParameters,
                filter: filter,
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
    private func openSendOrSelector(
        matches: [MainQRWalletModelMatch],
        unfilteredMatchCount: Int,
        sendParameters: PredefinedSendParameters,
        filter: MainQRScanTokenSelectorAvailabilityFilter,
        noSupportedTokensContext: MainQRNoSupportedTokensContext?
    ) {
        let resolution = Self.resolveMatchDestination(matches: matches, unfilteredMatchCount: unfilteredMatchCount)

        switch resolution {
        case .selfAddress:
            showSelfAddressAlert()
        case .noSupportedTokens:
            showNoSupportedTokensAlert(context: noSupportedTokensContext)
        case .singleMatch(let match):
            openSend(with: match, parameters: sendParameters)
        case .tokenSelector:
            openTokenSelector(filter: filter, sendParameters: sendParameters)
        }
    }

    @MainActor
    private func openTokenSelector(
        filter: MainQRScanTokenSelectorAvailabilityFilter,
        sendParameters: PredefinedSendParameters
    ) {
        closeScanner()

        let walletsProvider = CommonTokenSelectorWalletsProvider(accountModelFilter: \.isStandard)
        let selectorViewModel = TokenSelectorViewModel(
            walletsProvider: walletsProvider,
            availabilityProvider: MainQRScanTokenSelectorAvailabilityProvider(filter: filter)
        )
        let accountsModeSingleAccountHeaders = makeAccountsModeSingleAccountHeaders(
            walletItemViewModels: selectorViewModel.wallets,
            wallets: walletsProvider.wallets
        )

        tokenSelectorViewModel = MainQRScanTokenSelectorViewModel(
            tokenSelectorViewModel: selectorViewModel,
            sendParameters: sendParameters,
            accountsModeSingleAccountHeaders: accountsModeSingleAccountHeaders,
            coordinator: self
        )
        viewState = .tokenSelector

        Analytics.log(.sendChooseTokenScreenOpened)
    }

    @MainActor
    private func openSend(with match: MainQRWalletModelMatch, parameters: PredefinedSendParameters) {
        closeScanner()
        tokenSelectorViewModel = nil

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
    }

    @MainActor
    private func showUnrecognizedAlert() {
        turnOffScannerFlashIfNeeded()

        Analytics.log(event: .mainScreenNoticeUnrecognizedQR, params: [.qrType: "Unrecognized"])

        alert = alertFactory.makeUnrecognizedAlert { [weak self] in
            self?.rearmScanner()
        }
    }

    @MainActor
    private func showNoSupportedTokensAlert(context: MainQRNoSupportedTokensContext? = nil) {
        turnOffScannerFlashIfNeeded()

        var analyticsParams: [Analytics.ParameterKey: String] = [:]
        if let context {
            analyticsParams[.qrType] = context.qrType ?? Analytics.ParameterValue.paymentUri.rawValue
            analyticsParams[.blockchain] = context.networkId ?? ""
        } else {
            analyticsParams[.qrType] = Analytics.ParameterValue.plainAddress.rawValue
        }
        Analytics.log(event: .sendNoticeNoAvailableTokens, params: analyticsParams)

        alert = alertFactory.makeNoSupportedTokensAlert { [weak self] in
            self?.rearmScanner()
        }
    }

    @MainActor
    private func showUnknownParametersAlert(request: MainQRResolvedPaymentRequest, allMatches: [MainQRWalletModelMatch]) {
        turnOffScannerFlashIfNeeded()

        let parameterNames = request.request.unknownParameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")

        alert = alertFactory.makeUnknownParametersAlert(
            parameterNames: parameterNames,
            onContinue: { [weak self] in
                self?.handlePayment(request: request, allMatches: allMatches)
            },
            onCancel: { [weak self] in
                self?.rearmScanner()
            }
        )
    }

    @MainActor
    private func handlePayment(request: MainQRResolvedPaymentRequest, allMatches: [MainQRWalletModelMatch]) {
        Task { [weak self] in
            guard let self else { return }

            let (matchResult, sendParameters, filter) = await resolvePaymentRoute(request: request, allMatches: allMatches)

            guard qrScanCoordinator != nil else { return }

            openSendOrSelector(
                matches: matchResult.filtered,
                unfilteredMatchCount: matchResult.unfilteredCount,
                sendParameters: sendParameters,
                filter: filter,
                noSupportedTokensContext: .payment(request.request)
            )
        }
    }

    @MainActor
    private func showSelfAddressAlert() {
        turnOffScannerFlashIfNeeded()

        alert = alertFactory.makeSelfAddressAlert { [weak self] in
            self?.rearmScanner()
        }
    }

    private func isSelfAddress(walletModel: any WalletModel, destination: String) -> Bool {
        let blockchain = walletModel.tokenItem.blockchain
        guard !blockchain.supportsCompound else {
            return false
        }

        return walletModel.addresses.contains { $0.caseInsensitiveCompare(destination) == .orderedSame }
    }

    private func filterOutSelfAddressMatches(
        _ matches: [MainQRWalletModelMatch],
        destination: String
    ) -> [MainQRWalletModelMatch] {
        matches.filter { !isSelfAddress(walletModel: $0.walletModel, destination: destination) }
    }

    // MARK: - Background Processing

    private func resolveRouteAction(code: String) async -> ResolvedRouteAction {
        let context = walletModelMatcher.collectContext()
        let action = routeResolver.resolve(
            scannedCode: code,
            availableBlockchains: context.allBlockchains,
            availableTokenItems: context.allTokenItems
        )

        switch action {
        case .walletConnect(let uri):
            return .walletConnect(uri)

        case .payment(let request):
            return .payment(request, allMatches: context.allMatches)

        case .address(let request):
            let sendParameters = sendParametersFactory.makeSendParameters(
                destination: request.destinationAddress,
                amount: nil,
                tag: nil
            )
            let matches = walletModelMatcher.filterMatches(context.allMatches, for: request.matchingBlockchains)
            let filtered = filterOutSelfAddressMatches(matches, destination: request.destinationAddress)
            let matchResult = MatchFilterResult(filtered: filtered, unfilteredCount: matches.count)
            return .address(matchResult, sendParameters: sendParameters, filter: .blockchains(Set(request.matchingBlockchains)))

        case .showNoSupportedTokens(let noTokensContext):
            return .showNoSupportedTokens(noTokensContext)

        case .showUnrecognized:
            return .showUnrecognized
        }
    }

    private func resolvePaymentRoute(
        request: MainQRResolvedPaymentRequest,
        allMatches: [MainQRWalletModelMatch]
    ) async -> (MatchFilterResult, PredefinedSendParameters, MainQRScanTokenSelectorAvailabilityFilter) {
        let amount = resolvePaymentAmount(request: request.request, matchingTokenItems: request.matchingTokenItems)
        let sendParameters = sendParametersFactory.makeSendParameters(
            destination: request.request.destinationAddress,
            amount: amount,
            tag: request.request.memo
        )
        let matches = walletModelMatcher.filterMatches(allMatches, for: request.matchingTokenItems)
        let filtered = filterOutSelfAddressMatches(matches, destination: request.request.destinationAddress)
        let matchResult = MatchFilterResult(filtered: filtered, unfilteredCount: matches.count)
        let filter = MainQRScanTokenSelectorAvailabilityFilter.tokenItems(Set(request.matchingTokenItems))
        return (matchResult, sendParameters, filter)
    }

    private func resolvePaymentAmount(request: MainQRPaymentRequest, matchingTokenItems: [TokenItem]) -> Decimal? {
        if let amount = request.amount {
            return amount
        }

        guard let rawTokenAmount = request.rawTokenAmount, let tokenItem = matchingTokenItems.first else {
            return nil
        }

        let decimalCount = tokenItem.decimalCount
        guard decimalCount > 0 else {
            return rawTokenAmount
        }

        return rawTokenAmount / pow(10, decimalCount)
    }

    private func rearmScanner() {
        Task { @MainActor [weak self] in
            self?.qrScanCoordinator?.rearmForNextScan()
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

    private func makeAccountsModeSingleAccountHeaders(
        walletItemViewModels: [TokenSelectorWalletItemViewModel],
        wallets: [TokenSelectorWallet]
    ) -> [ObjectIdentifier: TokenSelectorAccountViewModel.HeaderType] {
        var result: [ObjectIdentifier: TokenSelectorAccountViewModel.HeaderType] = [:]

        for (walletItemViewModel, wallet) in zip(walletItemViewModels, wallets) {
            guard case .single(let account) = wallet.accounts else {
                continue
            }

            result[walletItemViewModel.id] = .account(
                icon: AccountModelUtils.UI.iconViewData(accountModel: account.account),
                name: account.account.name
            )
        }

        return result
    }
}

// MARK: - Supporting Types

extension MainQRScanFlowCoordinator {
    struct MatchFilterResult {
        let filtered: [MainQRWalletModelMatch]
        let unfilteredCount: Int
    }

    enum MatchDestination {
        case selfAddress
        case noSupportedTokens
        case singleMatch(MainQRWalletModelMatch)
        case tokenSelector
    }

    enum ResolvedRouteAction {
        case walletConnect(WalletConnectRequestURI)
        case payment(MainQRResolvedPaymentRequest, allMatches: [MainQRWalletModelMatch])
        case address(MatchFilterResult, sendParameters: PredefinedSendParameters, filter: MainQRScanTokenSelectorAvailabilityFilter)
        case showNoSupportedTokens(MainQRNoSupportedTokensContext?)
        case showUnrecognized
    }

    static func resolveMatchDestination(
        matches: [MainQRWalletModelMatch],
        unfilteredMatchCount: Int
    ) -> MatchDestination {
        switch matches.count {
        case 0:
            return unfilteredMatchCount > 0 ? .selfAddress : .noSupportedTokens
        case 1:
            return .singleMatch(matches[0])
        default:
            let matchesWithBalance = matches.filter { match in
                if case .loaded(let balance) = match.walletModel.availableBalanceProvider.balanceType, balance > 0 {
                    return true
                }
                return false
            }
            if matchesWithBalance.count == 1, let singleMatch = matchesWithBalance.first {
                return .singleMatch(singleMatch)
            }
            return .tokenSelector
        }
    }
}

// MARK: - Options

extension MainQRScanFlowCoordinator {
    struct Options {}

    enum ViewState: Identifiable {
        case scanner
        case tokenSelector
        case send

        var id: String {
            switch self {
            case .scanner:
                return "scanner"
            case .tokenSelector:
                return "tokenSelector"
            case .send:
                return "send"
            }
        }
    }
}

// MARK: - MainQRScanTokenSelectorRoutable

extension MainQRScanFlowCoordinator: MainQRScanTokenSelectorRoutable {
    func didSelectToken(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        sendParameters: PredefinedSendParameters
    ) {
        if isSelfAddress(walletModel: walletModel, destination: sendParameters.destination) {
            showSelfAddressAlert()
            return
        }

        let tokenItem = walletModel.tokenItem
        Analytics.log(event: .sendTokenSelected, params: [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
        ])

        openSend(
            with: MainQRWalletModelMatch(walletModel: walletModel, userWalletInfo: userWalletInfo),
            parameters: sendParameters
        )
    }

    func closeTokenSelector() {
        tokenSelectorViewModel = nil
        dismissAction(())
    }
}
