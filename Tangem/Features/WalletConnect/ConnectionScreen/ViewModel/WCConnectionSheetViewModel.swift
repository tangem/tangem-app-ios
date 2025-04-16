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
import ReownWalletKit

@MainActor
final class WCConnectionSheetViewModel: FloatingSheetContentViewModel, ObservableObject {
    // MARK: Dependencies

    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: FloatingSheetPresenter

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    // MARK: Private properties

    @Published
    private(set) var isConnectionRequestDescriptionVisible = false
    
    @Published
    private(set) var isConnectionLoadingIndicatorVisible = false

    @Published
    private(set) var request: WCConnectionRequestModel?

    private let tokenIconInfoBuilder = TokenIconInfoBuilder()
    private let requestPublisher: AnyPublisher<WCConnectionRequestModel?, Never>
    private let connectionInProgressPublisher: AnyPublisher<Bool, Never>

    private var bag = Set<AnyCancellable>()
    private var tokenItemMapper: TokenItemMapper? {
        guard
            let selectedUserWalletModel = userWalletRepository.models.first(where: { $0.userWalletId.stringValue == request?.userWalletModelId })
        else {
            return nil
        }

        return TokenItemMapper(supportedBlockchains: selectedUserWalletModel.config.supportedBlockchains)
    }

    // MARK: Public properties

    let id = UUID().uuidString
    let proposal: Session.Proposal

    var selectedWalletName: String {
        userWalletRepository.models.first { $0.userWalletId.stringValue == request?.userWalletModelId }?.name ?? ""
    }

    init(
        requestPublisher: AnyPublisher<WCConnectionRequestModel?, Never>,
        connectionInProgressPublisher: AnyPublisher<Bool, Never>,
        proposal: Session.Proposal
    ) {
        self.requestPublisher = requestPublisher
        self.connectionInProgressPublisher = connectionInProgressPublisher
        self.proposal = proposal

        bind()
    }

    func bind() {
        requestPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, requestValue in
                viewModel.request = requestValue
            }
            .store(in: &bag)
        
        connectionInProgressPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, inProgress in
                viewModel.isConnectionLoadingIndicatorVisible = inProgress
                
                if !inProgress {
                    viewModel.floatingSheetPresenter.removeActiveSheet()
                }
            }
            .store(in: &bag)
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .dismissConnectionView:
            floatingSheetPresenter.removeActiveSheet()
        case .showConnectionDescription:
            withAnimation { isConnectionRequestDescriptionVisible.toggle() }
        case .connect:
            request?.connect()
        case .cancel:
            request?.cancel()
        }
    }

    func makeTokenIconsInfo() -> [TokenIconInfo] {
        request?.selectedNetworks.compactMap { blockchain -> TokenIconInfo? in
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
    }
}

extension WCConnectionSheetViewModel {
    enum ViewAction {
        case dismissConnectionView
        case showConnectionDescription
        case connect
        case cancel
    }
}
