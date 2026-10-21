//
//  MainHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemUI
import TangemFoundation

final class MainHeaderViewModel: ObservableObject {
    let isUserWalletLocked: Bool

    @Published private(set) var userWalletName: String = ""
    @Published private(set) var balance: LoadableBalanceView.State
    @Published private(set) var walletThumbnailType: ThumbnailWalletViewType?
    @Published private(set) var subtitleViewState: MainHeaderSubtitleViewState = .text

    private let userWalletId: UserWalletId

    private weak var supplementInfoProvider: MainHeaderSupplementInfoProvider?
    private let balanceProvider: MainHeaderBalanceProvider
    private let walletAssetsDiscoveryProgressProvider: WalletAssetsDiscoveryProgressProvider
    private let updatePublisher: AnyPublisher<UpdateResult, Never>

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletId: UserWalletId,
        isUserWalletLocked: Bool,
        walletThumbnailType: ThumbnailWalletViewType?,
        supplementInfoProvider: MainHeaderSupplementInfoProvider,
        balanceProvider: MainHeaderBalanceProvider,
        walletAssetsDiscoveryProgressProvider: WalletAssetsDiscoveryProgressProvider,
        updatePublisher: AnyPublisher<UpdateResult, Never>
    ) {
        self.userWalletId = userWalletId
        self.isUserWalletLocked = isUserWalletLocked
        self.walletThumbnailType = walletThumbnailType
        self.supplementInfoProvider = supplementInfoProvider
        self.balanceProvider = balanceProvider
        self.walletAssetsDiscoveryProgressProvider = walletAssetsDiscoveryProgressProvider
        self.updatePublisher = updatePublisher
        userWalletName = supplementInfoProvider.name
        balance = balanceProvider.balance

        bind()
        bindWalletAssetsDiscoveryProgressProvider()
    }

    private func bind() {
        supplementInfoProvider?.updatePublisher
            .compactMap(\.newName)
            .receive(on: DispatchQueue.main)
            .assign(to: \.userWalletName, on: self, ownership: .weak)
            .store(in: &bag)

        balanceProvider.balancePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.balance, on: self, ownership: .weak)
            .store(in: &bag)

        updatePublisher
            .receive(on: DispatchQueue.main)
            .compactMap { event -> UserWalletModel? in
                if case .configurationChanged(let model) = event {
                    return model
                } else {
                    return nil
                }
            }
            .map(\.config.walletThumbnailType)
            .assign(to: \.walletThumbnailType, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func bindWalletAssetsDiscoveryProgressProvider() {
        Task { @MainActor in
            if let walletAssetsDiscoveryProgressPublisher = await walletAssetsDiscoveryProgressProvider.progressPublisher(for: userWalletId) {
                walletAssetsDiscoveryProgressPublisher
                    .map { percent in
                        (1 ..< 100).contains(percent) ? .progress(value: percent) : .text
                    }
                    .removeDuplicates()
                    .receiveOnMain()
                    .assign(to: \.subtitleViewState, on: self, ownership: .weak)
                    .store(in: &bag)
            }
        }
    }
}
