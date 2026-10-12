//
//  ReferralWidgetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

final class ReferralWidgetProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.referralProgramInfoRepository) private var referralProgramInfoRepository: ReferralProgramInfoRepository

    private let widgetSubject = CurrentValueSubject<FeedWidget?, Never>(nil)
    private let candidatesSubject = CurrentValueSubject<[FeedReferralWalletCandidate], Never>([])
    private let rewardFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = Constants.rewardMaximumFractionDigits
        return formatter
    }()

    private let router: any ReferralFeedRoutable

    private var wallets: [UserWalletModel] = []
    private var infos: [UserWalletId: ReferralProgramInfo] = [:]
    private var requestedWalletIds: Set<UserWalletId> = []
    private var failedWalletIds: Set<UserWalletId> = []
    private var hasRefreshed = false
    private var bag = Set<AnyCancellable>()
    private var walletBag = Set<AnyCancellable>()

    init(router: any ReferralFeedRoutable) {
        self.router = router

        bind()
    }
}

// MARK: - FeedWidgetProvider

extension ReferralWidgetProvider: FeedWidgetProvider {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        widgetSubject.removeDuplicates().eraseToAnyPublisher()
    }

    func refresh() {
        hasRefreshed = true

        for wallet in wallets {
            let walletId = wallet.userWalletId
            guard requestedWalletIds.insert(walletId).inserted else { continue }

            failedWalletIds.remove(walletId)

            runTask(in: self) { provider in
                do {
                    _ = try await provider.referralProgramInfoRepository.loadInfo(for: walletId)
                } catch {
                    await runOnMain {
                        provider.requestedWalletIds.remove(walletId)
                        provider.failedWalletIds.insert(walletId)
                        provider.resolveWidget()
                    }
                }
            }
        }

        resolveWidget()
    }

    func select() {
        router.openReferral(
            candidates: candidatesSubject.value,
            candidatesPublisher: candidatesSubject.removeDuplicates().eraseToAnyPublisher(),
            resolveAvailableWallet: { [weak self] walletId in
                self?.resolveAvailableWallet(walletId)
            },
            onDismiss: { [weak self] walletId in
                self?.requestedWalletIds.remove(walletId)
                self?.refresh()
            }
        )
    }
}

// MARK: - Private

private extension ReferralWidgetProvider {
    func bind() {
        userWalletRepository.eventProvider
            .filter { event in
                switch event {
                case .selected: false
                default: true
                }
            }
            .mapToVoid()
            .prepend(())
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, _ in provider.bindWallets() }
            .store(in: &bag)
    }

    func bindWallets() {
        walletBag.removeAll()

        let unlockedWallets = userWalletRepository.models.filter { !$0.isUserWalletLocked }
        wallets = unlockedWallets.filter { $0.config.hasFeature(.referralProgram) }
        let walletIds = Set(wallets.map(\.userWalletId))
        infos = infos.filter { walletIds.contains($0.key) }
        requestedWalletIds.formIntersection(walletIds)
        failedWalletIds.formIntersection(walletIds)

        Publishers.MergeMany(unlockedWallets.map { wallet in
            wallet.updatePublisher.filter { update in
                guard case .configurationChanged = update else { return false }
                return true
            }
        })
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { provider, _ in provider.bindWallets() }
        .store(in: &walletBag)

        guard !wallets.isEmpty else {
            resolveWidget()
            return
        }

        wallets.map { wallet in
            referralProgramInfoRepository.infoPublisher(for: wallet.userWalletId)
                .map { (wallet.userWalletId, $0) }
                .eraseToAnyPublisher()
        }
        .combineLatest()
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .sink { provider, infos in
            provider.infos = infos.reduce(into: [:]) { result, entry in
                result[entry.0] = entry.1
            }
            provider.resolveWidget()
        }
        .store(in: &walletBag)

        if hasRefreshed {
            refresh()
        } else {
            resolveWidget()
        }
    }

    func resolveWidget() {
        let candidates = userWalletRepository.models.map(makeCandidate(for:))
        candidatesSubject.send(candidates)

        let widget: FeedWidget? = if let reward = candidates.lazy.compactMap(\.reward).first {
            .referFriend(reward: .success(reward))
        } else if candidates.contains(where: { $0.state == .loading }) {
            .referFriend(reward: .loading)
        } else if candidates.contains(where: { $0.state == .failure }) {
            .referFriend(reward: .failure(FeedWidget.LoadError()))
        } else {
            nil
        }

        widgetSubject.send(widget)
    }

    func makeCandidate(for wallet: UserWalletModel) -> FeedReferralWalletCandidate {
        guard !wallet.isUserWalletLocked, wallet.config.hasFeature(.referralProgram) else {
            return .init(wallet: wallet, state: .unavailable)
        }

        guard let info = infos[wallet.userWalletId] else {
            return .init(wallet: wallet, state: failedWalletIds.contains(wallet.userWalletId) ? .failure : .loading)
        }

        guard let reward = makeReward(info: info, config: wallet.config) else {
            return .init(wallet: wallet, state: .unavailable)
        }

        return .init(wallet: wallet, state: .available(reward: reward))
    }

    func resolveAvailableWallet(_ walletId: UserWalletId) -> UserWalletModel? {
        guard let wallet = userWalletRepository.models.first(where: { $0.userWalletId == walletId }),
              makeCandidate(for: wallet).isAvailable else { return nil }

        return wallet
    }

    func makeReward(info: ReferralProgramInfo, config: UserWalletConfig) -> String? {
        guard info.referral == nil,
              let award = info.conditions.awards.first,
              config.supportedBlockchains.contains(where: { $0.networkId == award.token.networkId }),
              award.token.storageToken != nil, award.amount > 0 else {
            return nil
        }

        guard let amount = rewardFormatter.string(from: award.amount as NSDecimalNumber) else { return nil }

        return "\(amount) \(award.token.symbol)"
    }
}

// MARK: - Constants

private extension ReferralWidgetProvider {
    enum Constants {
        static let rewardMaximumFractionDigits = 8
    }
}
