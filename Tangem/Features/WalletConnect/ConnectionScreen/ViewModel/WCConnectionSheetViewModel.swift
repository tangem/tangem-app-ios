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
    @Injected(\.floatingSheetPresenter)
    private var floatingSheetPresenter: FloatingSheetPresenter

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    @Published
    private(set) var isConnectionRequestDescriptionVisible = false

    @Published
    private(set) var request: WCConnectionRequestModel?

    private let requestPublisher: AnyPublisher<WCConnectionRequestModel?, Never>
    private var requestBag: AnyCancellable?

    let id = UUID().uuidString
    let proposal: Session.Proposal

    var selectedWalletName: String {
        userWalletRepository.models.first { $0.userWalletId.stringValue == request?.userWalletModelId }?.name ?? ""
    }
    
    var tokenIcons: [TokenIconInfo] {
        guard let supportedBlockchains = userWalletRepository.selectedModel?.config.supportedBlockchains else { return [] }
        
        let tokenIconInfoBuilder = TokenIconInfoBuilder()
        let tokenItemMapper = TokenItemMapper(supportedBlockchains: supportedBlockchains)

        return request?.selectedNetworks.compactMap { blockchain -> TokenIconInfo? in
            guard
            let tokenItem = tokenItemMapper.mapToTokenItem(
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

    init(
        requestPublisher: AnyPublisher<WCConnectionRequestModel?, Never>,
        proposal: Session.Proposal
    ) {
        self.requestPublisher = requestPublisher
        self.proposal = proposal
        
        bind()
    }

    func bind() {
        requestBag = requestPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, requestValue in
                viewModel.request = requestValue
            }
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
}

extension WCConnectionSheetViewModel {
    enum ViewAction {
        case dismissConnectionView
        case showConnectionDescription
        case connect
        case cancel
    }
}
