//
//  MCPConnectionRequestUserWalletSelectorRowViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import protocol Combine.ObservableObject
import struct Combine.Published

@MainActor
final class MCPConnectionRequestUserWalletSelectorRowViewModel: ObservableObject, HashableObject, Identifiable {
    private let imageRepository: MCPUserWalletImageRepository
    private let balanceUpdater: (MCPUserWallet.ID) -> AsyncStream<String>
    private let tapAction: (MCPConnectionRequestUserWalletSelectorRowState) -> Void

    private var imageTask: Task<Void, Never>?
    private var balanceUpdateTask: Task<Void, Never>?

    @Published private(set) var state: MCPConnectionRequestUserWalletSelectorRowState

    init(
        state: MCPConnectionRequestUserWalletSelectorRowState,
        imageRepository: MCPUserWalletImageRepository,
        balanceUpdater: @escaping (MCPUserWallet.ID) -> AsyncStream<String>,
        tapAction: @escaping (MCPConnectionRequestUserWalletSelectorRowState) -> Void
    ) {
        self.imageRepository = imageRepository
        self.balanceUpdater = balanceUpdater
        self.state = state
        self.tapAction = tapAction
    }

    deinit {
        imageTask?.cancel()
        balanceUpdateTask?.cancel()
    }

    func handle(action: MCPConnectionRequestUserWalletSelectorRowAction) {
        switch action {
        case .viewDidLoad:
            handleViewDidLoad()

        case .viewTapped:
            tapAction(state)

        case .imageLoaded(let userWalletImage):
            state.image = .content(userWalletImage)
            imageTask = nil

        case .balanceUpdated(let balanceUpdate):
            assert(!state.userWallet.isLocked, "Locked UserWallet received balance update. Developer mistake.")
            state.subtitle.balance = balanceUpdate

        case .isSelectedChanged(let isSelected):
            state.isSelected = isSelected
        }
    }

    private func handleViewDidLoad() {
        let userWalletID = state.userWallet.id

        imageTask?.cancel()
        imageTask = Task { [weak self, imageRepository] in
            let image = await imageRepository.retrieve(by: userWalletID)
            self?.handle(action: .imageLoaded(image))
        }

        guard !state.userWallet.isLocked else {
            return
        }

        let balanceUpdateStream = balanceUpdater(userWalletID)

        balanceUpdateTask?.cancel()
        balanceUpdateTask = Task { [weak self] in
            for await balanceUpdate in balanceUpdateStream {
                self?.handle(action: .balanceUpdated(balanceUpdate))
            }
        }
    }
}
