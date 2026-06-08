//
//  MainHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemUI
import TangemFoundation

final class MainHeaderViewModel: ObservableObject {
    let isUserWalletLocked: Bool

    @Published private(set) var cardImage: ImageType?
    @Published private(set) var userWalletName: String = ""
    @Published private(set) var subtitleInfo: MainHeaderSubtitleInfo = .empty
    @Published private(set) var balance: LoadableBalanceView.State
    @Published private(set) var walletThumbnailType: ThumbnailWalletViewType?
    @Published var isLoadingSubtitle: Bool = true
    @Published private(set) var subtitleViewState: MainHeaderSubtitleViewState = .text

    var subtitleContainsSensitiveInfo: Bool {
        subtitleProviderSubject.value.containsSensitiveInfo
    }

    private let userWalletId: UserWalletId

    private weak var supplementInfoProvider: MainHeaderSupplementInfoProvider?
    private let subtitleProviderSubject: CurrentValueSubject<MainHeaderSubtitleProvider, Never>
    private let balanceProvider: MainHeaderBalanceProvider
    private let walletAssetsDiscoveryProgressProvider: WalletAssetsDiscoveryProgressProvider
    private let updatePublisher: AnyPublisher<UpdateResult, Never>

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletId: UserWalletId,
        isUserWalletLocked: Bool,
        walletThumbnailType: ThumbnailWalletViewType?,
        supplementInfoProvider: MainHeaderSupplementInfoProvider,
        subtitleProvider: MainHeaderSubtitleProvider,
        balanceProvider: MainHeaderBalanceProvider,
        walletAssetsDiscoveryProgressProvider: WalletAssetsDiscoveryProgressProvider,
        updatePublisher: AnyPublisher<UpdateResult, Never>
    ) {
        self.userWalletId = userWalletId
        self.isUserWalletLocked = isUserWalletLocked
        self.walletThumbnailType = walletThumbnailType
        self.supplementInfoProvider = supplementInfoProvider
        subtitleProviderSubject = CurrentValueSubject(subtitleProvider)
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

        supplementInfoProvider?.walletHeaderImagePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.cardImage, on: self, ownership: .weak)
            .store(in: &bag)

        subtitleProviderSubject
            .map { $0.isLoadingPublisher }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoadingSubtitle, on: self, ownership: .weak)
            .store(in: &bag)

        subtitleProviderSubject
            .map { $0.subtitlePublisher }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .assign(to: \.subtitleInfo, on: self, ownership: .weak)
            .store(in: &bag)

        balanceProvider.balancePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.balance, on: self, ownership: .weak)
            .store(in: &bag)

        updatePublisher
            .receive(on: DispatchQueue.main)
            .compactMap { event in
                if case .configurationChanged(let model) = event {
                    let containsDefaultToken = model.config.hasDefaultToken
                    let isMultiWalletPage = model.config.hasFeature(.multiCurrency) || containsDefaultToken
                    let providerFactory = model.config.makeMainHeaderProviderFactory()
                    let subtitleProvider = providerFactory.makeHeaderSubtitleProvider(for: model, isMultiWallet: isMultiWalletPage)
                    return (subtitleProvider, model.config.walletThumbnailType)
                } else {
                    return nil
                }
            }
            .sink { [weak self] subtitleProvider, walletThumbnailType in
                self?.subtitleProviderSubject.send(subtitleProvider)
                self?.walletThumbnailType = walletThumbnailType
            }
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
