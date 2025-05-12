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

@MainActor
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

    // MARK: Published properties

    @Published
    private(set) var presentationState: PresentationState = .dappInfoLoading

    @Published
    private(set) var request: WCConnectionRequestModel?

    @Published
    private(set) var proposal: Session.Proposal?

    var isWalletSelectorVisible: Bool {
        userWalletRepository.models.count > 1
    }

    // MARK: Private properties

    private let tokenIconInfoBuilder = TokenIconInfoBuilder()
    private let requestPublisher: AnyPublisher<WCConnectionRequestModel?, Never>
    private let proposalPublisher: AnyPublisher<Session.Proposal?, Never>
    private let dappInfoLoadingPublisher: AnyPublisher<Bool, Never>
    private let contentSwitchAnimation: Animation = .timingCurve(0.69, 0.07, 0.27, 0.95, duration: 0.5)

    private var bag = Set<AnyCancellable>()

    private var tokenItemMapper: TokenItemMapper? {
        guard
            let selectedUserWalletModel = userWalletRepository.models.first(where: {
                $0.userWalletId.stringValue == request?.userWalletModelId
            })
        else {
            return nil
        }

        return TokenItemMapper(supportedBlockchains: selectedUserWalletModel.config.supportedBlockchains)
    }

    init(
        requestPublisher: AnyPublisher<WCConnectionRequestModel?, Never>,
        dappInfoLoadingPublisher: AnyPublisher<Bool, Never>,
        proposalPublisher: AnyPublisher<Session.Proposal?, Never>
    ) {
        self.requestPublisher = requestPublisher
        self.dappInfoLoadingPublisher = dappInfoLoadingPublisher
        self.proposalPublisher = proposalPublisher

        bind()
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .dismissConnectionView:
            cancel()
        case .showUserWallets:
            showUserWallets()
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
            .receive(on: DispatchQueue.main)
            .assign(to: \.request, on: self, ownership: .weak)
            .store(in: &bag)

        dappInfoLoadingPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, isDappInfoLoading in
                viewModel.presentationState = isDappInfoLoading ? .dappInfoLoading : .connectionDetails
            }
            .store(in: &bag)

        proposalPublisher
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .assign(to: \.proposal, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - Button actions

extension WCConnectionSheetViewModel {
    private func connect() {
        Task { [weak self] in
            guard let self else { return }

            do {
                presentationState = .connecting
                try await request?.connect()
                presentationState = .connectionDetails
                floatingSheetPresenter.removeActiveSheet()

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

    private func cancel() {
        request?.cancel()
        floatingSheetPresenter.removeActiveSheet()
    }

    func showUserWallets() {
        guard userWalletRepository.models.filter({ !$0.isUserWalletLocked }).count > 1 else { return }

        withAnimation(contentSwitchAnimation) {
            presentationState = .walletSelector
        }
    }

    func selectUserWallet(_ userWalletModel: some UserWalletModel) {
        wcService.updateSelectedWalletId(userWalletModel.userWalletId.stringValue)

        withAnimation(contentSwitchAnimation) {
            presentationState = .connectionDetails
        }
    }

    func returnToConnectionDetails() {
        withAnimation(contentSwitchAnimation) {
            presentationState = .connectionDetails
        }
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

    var userWalletModels: [UserWalletModel] {
        userWalletRepository.models
    }

    var selectedUserWalletId: String {
        request?.userWalletModelId ?? ""
    }

    var isOtherWalletSelectorVisible: Bool {
        userWalletRepository.models.filter { !$0.isUserWalletLocked }.count > 1
    }

    func makeTokenIconsInfo() -> [TokenIconInfo] {
        let items = request?.selectedNetworks.compactMap { blockchain -> TokenIconInfo? in
            guard
                let tokenItem = tokenItemMapper?.mapToTokenItem(
                    id: blockchain.coinId,
                    name: blockchain.coinDisplayName,
                    symbol: blockchain.currencySymbol,
                    network: .init(
                        networkId: blockchain.networkId,
                        contractAddress: nil,
                        decimalCount: blockchain.decimalCount
                    )
                )
            else {
                return nil
            }

            return tokenIconInfoBuilder.build(from: tokenItem, isCustom: false)
        } ?? []

        return items
    }

    private func makeWarningToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }
}

// MARK: - Presentation state

extension WCConnectionSheetViewModel {
    enum PresentationState: Equatable {
        case connectionDetails
        case walletSelector
        case dappInfoLoading
        case connecting
        case error
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
        case returnToConnectionDetails
    }
}
