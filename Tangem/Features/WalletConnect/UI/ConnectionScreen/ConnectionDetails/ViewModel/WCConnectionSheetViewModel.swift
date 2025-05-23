//
//  WCConnectionSheetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk
import TangemUI
import TangemFoundation
import ReownWalletKit

final class WCConnectionSheetViewModel: FloatingSheetContentViewModel, ObservableObject {
    // MARK: Dependencies

    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: FloatingSheetPresenter

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Injected(\.wcService)
    private var wcService: any WCService

    // MARK: Public properties

    let id = UUID().uuidString
    private(set) var blockchains: [WCSelectedBlockchainItem] = []
    private(set) var tokenIconsInfo: [TokenIconInfo] = []
    private(set) var requiredBlockchainNames: [String] = []

    // MARK: Published properties

    @Published
    private(set) var presentationState: PresentationState = .dappInfoLoading {
        didSet {
            previousState = oldValue
        }
    }

    @Published
    private(set) var request: WCConnectionRequestModel?

    @Published
    private(set) var proposal: Session.Proposal?

    @Published var contentHeight: CGFloat = 0

    // MARK: Private properties

    private let tokenIconInfoBuilder = TokenIconInfoBuilder()
    private let requestPublisher: AnyPublisher<WCConnectionRequestModel?, Never>
    private let proposalPublisher: AnyPublisher<Session.Proposal?, Never>
    private let dappInfoLoadingPublisher: AnyPublisher<Bool, Never>
    private let errorsPublisher: AnyPublisher<(error: WalletConnectV2Error, dAppName: String), Never>
    private let contentSwitchAnimation: Animation = .timingCurve(0.69, 0.07, 0.27, 0.95, duration: 0.5)

    private var bag = Set<AnyCancellable>()
    private(set) var previousState: PresentationState = .dappInfoLoading

    var containerHeight: CGFloat = 0

    init(
        requestPublisher: AnyPublisher<WCConnectionRequestModel?, Never>,
        dappInfoLoadingPublisher: AnyPublisher<Bool, Never>,
        proposalPublisher: AnyPublisher<Session.Proposal?, Never>,
        errorsPublisher: AnyPublisher<(error: WalletConnectV2Error, dAppName: String), Never>
    ) {
        self.requestPublisher = requestPublisher
        self.dappInfoLoadingPublisher = dappInfoLoadingPublisher
        self.proposalPublisher = proposalPublisher
        self.errorsPublisher = errorsPublisher

        bind()
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .dismissConnectionView:
            cancel()
        case .showUserWallets:
            showUserWallets()
        case .showUserNetworks:
            showUserNetworks()
        case .selectUserWallet(let userWalletModel):
            selectUserWallet(userWalletModel)
        case .returnToConnectionDetails:
            returnToConnectionDetails()
        case .connect:
            connect()
        case .cancel:
            cancel()
        }
    }
}

// MARK: - Subscriptions

extension WCConnectionSheetViewModel {
    func bind() {
        requestPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, request in
                guard let request else { return }

                viewModel.blockchains = request.blockchains.compactMap {
                    .init(
                        from: $0,
                        tokenItemMapper: viewModel.makeTokenItemMapper(for: request.userWalletModelId),
                        tokenIconInfoBuilder: viewModel.tokenIconInfoBuilder
                    )
                }.sorted(by: { $0.name < $1.name })

                viewModel.requiredBlockchainNames = viewModel.blockchains.compactMap {
                    $0.state == .requiredToAdd ? $0.name : nil
                }

                viewModel.tokenIconsInfo = viewModel.blockchains.compactMap(\.tokenIconInfo)

                viewModel.request = request
            }
            .store(in: &bag)

        dappInfoLoadingPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isDappInfoLoading in
                if viewModel.presentationState == .dappInfoLoading {
                    withAnimation(.default) {
                        viewModel.presentationState = isDappInfoLoading ? .dappInfoLoading : .connectionDetails
                    }
                }
            }
            .store(in: &bag)

        proposalPublisher
            .receiveOnMain()
            .removeDuplicates()
            .assign(to: \.proposal, on: self, ownership: .weak)
            .store(in: &bag)

        errorsPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                if case .requiredChainsNotSatisfied = result.error {
                    withAnimation(viewModel.contentSwitchAnimation) {
                        viewModel.presentationState = .noRequiredChains
                    }
                }
            }
            .store(in: &bag)
    }
}

// MARK: - Button actions

private extension WCConnectionSheetViewModel {
    func connect() {
        Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                presentationState = .connecting

                try await request?.connect?()

                presentationState = .connectionDetails

                Task { @MainActor in
                    self.floatingSheetPresenter.removeActiveSheet()
                }

            } catch let error as WalletConnectV2Error {
                makeWarningToast(with: error.localizedDescription)
                presentationState = .connectionDetails
            } catch {
                let mappedError = WalletConnectV2ErrorMappingUtils().mapWCv2Error(error)

                makeWarningToast(with: mappedError.localizedDescription)
                presentationState = .connectionDetails
            }
        }
    }

    func cancel() {
        request?.cancel?()

        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func updateSelectedNetworks(_ selectedNetworks: [BlockchainNetwork]) {
        returnToConnectionDetails()
        wcService.updateSelectedNetworks(selectedNetworks)
    }

    func showUserWallets() {
        guard
            isConnectionDetailsPresented,
            userWalletRepository.models.filter({
                !$0.isUserWalletLocked && $0.config.hasFeature(.walletConnect)
            })
            .count > 1
        else {
            return
        }

        let input = WCWalletSelectorInput(
            selectedWalletId: selectedUserWalletId,
            userWalletModels: userWalletRepository.models,
            selectWallet: selectUserWallet(_:),
            backAction: returnToConnectionDetails
        )

        withAnimation(contentSwitchAnimation) {
            presentationState = .walletSelector(input)
        }
    }

    func showUserNetworks() {
        guard isConnectionDetailsPresented else { return }

        let input = WCNetworkSelectorInput(
            blockchains: blockchains,
            requiredBlockchainNames: requiredBlockchainNames,
            onSelectCompete: updateSelectedNetworks(_:),
            backAction: returnToConnectionDetails
        )

        withAnimation(contentSwitchAnimation) {
            presentationState = .networkSelector(input)
        }
    }

    func selectUserWallet(_ userWalletModel: UserWalletModel) {
        wcService.updateSelectedWalletId(userWalletModel.userWalletId.stringValue)

        withAnimation(contentSwitchAnimation) {
            presentationState = .connectionDetails
        }
    }

    func returnToConnectionDetails() {
        withAnimation(contentSwitchAnimation) {
            presentationState = previousState
        }
    }
}

// MARK: - Factory methods

extension WCConnectionSheetViewModel {
    private func makeWarningToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }

    private func makeTokenItemMapper(for userWalletModelId: String) -> TokenItemMapper? {
        guard
            let selectedUserWalletModel = userWalletRepository.models.first(where: {
                $0.userWalletId.stringValue == userWalletModelId
            })
        else {
            return nil
        }

        return TokenItemMapper(supportedBlockchains: selectedUserWalletModel.config.supportedBlockchains)
    }
}

// MARK: - UI Helpers

extension WCConnectionSheetViewModel {
    var selectedWalletName: String {
        if presentationState == .dappInfoLoading {
            userWalletRepository.selectedModel?.name ?? ""
        } else {
            userWalletRepository.models.first { $0.userWalletId.stringValue == request?.userWalletModelId }?.name ?? ""
        }
    }

    var isDappInfoLoading: Bool {
        presentationState == .dappInfoLoading
    }

    var isConnecting: Bool {
        presentationState == .connecting
    }

    var isConnectionButtonDisabled: Bool {
        presentationState != .connectionDetails
    }

    var isWalletSelectorVisible: Bool {
        userWalletRepository.models.count > 1
    }

    var isTransitionFromNetworkSelector: Bool {
        if case .networkSelector = previousState {
            return true
        }

        return false
    }

    var selectedUserWalletId: String {
        request?.userWalletModelId ?? ""
    }

    var isOtherWalletSelectorVisible: Bool {
        userWalletRepository.models.filter { !$0.isUserWalletLocked }.count > 1
    }

    var isConnectionDetailsPresented: Bool {
        let state: [PresentationState] = [.connecting, .connectionDetails, .dappInfoLoading, .error, .noRequiredChains]

        return state.contains(presentationState)
    }

    var isNetworksPreviewPresented: Bool {
        let state: [PresentationState] = [.connecting, .connectionDetails]

        return state.contains(presentationState)
    }
}

// MARK: - Presentation state

extension WCConnectionSheetViewModel {
    enum PresentationState: Equatable {
        case connectionDetails
        case walletSelector(WCWalletSelectorInput)
        case networkSelector(WCNetworkSelectorInput)
        case dappInfoLoading
        case connecting
        case error
        case noRequiredChains
    }
}

// MARK: - ViewAction

extension WCConnectionSheetViewModel {
    enum ViewAction {
        case dismissConnectionView
        case connect
        case cancel
        case selectUserWallet(UserWalletModel)
        case showUserWallets
        case showUserNetworks
        case returnToConnectionDetails
    }
}
