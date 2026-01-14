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

final class MainHeaderViewModel: ObservableObject {
    let isUserWalletLocked: Bool

    @Published private(set) var cardImage: ImageType?
    @Published private(set) var userWalletName: String = ""
    @Published private(set) var subtitleInfo: MainHeaderSubtitleInfo = .empty
    @Published private(set) var balance: LoadableTokenBalanceView.State
    @Published var isLoadingSubtitle: Bool = true

    var subtitleContainsSensitiveInfo: Bool {
        subtitleProviderSubject.value.containsSensitiveInfo
    }

    private weak var supplementInfoProvider: MainHeaderSupplementInfoProvider?
    private let subtitleProviderSubject: CurrentValueSubject<MainHeaderSubtitleProvider, Never>
    private let balanceProvider: MainHeaderBalanceProvider
    private let updatePublisher: AnyPublisher<UpdateResult, Never>

    private var bag: Set<AnyCancellable> = []

    init(
        isUserWalletLocked: Bool,
        supplementInfoProvider: MainHeaderSupplementInfoProvider,
        subtitleProvider: MainHeaderSubtitleProvider,
        balanceProvider: MainHeaderBalanceProvider,
        updatePublisher: AnyPublisher<UpdateResult, Never>
    ) {
        self.isUserWalletLocked = isUserWalletLocked
        self.supplementInfoProvider = supplementInfoProvider
        subtitleProviderSubject = CurrentValueSubject(subtitleProvider)
        self.balanceProvider = balanceProvider
        self.updatePublisher = updatePublisher
        userWalletName = supplementInfoProvider.name
        balance = balanceProvider.balance

        bind()
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
                    return subtitleProvider
                } else {
                    return nil
                }
            }
            .subscribe(subtitleProviderSubject)
            .store(in: &bag)
    }
}
