//
//  ReferralWidgetProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class ReferralWidgetProvider {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.referralProgramInfoRepository) private var referralProgramInfoRepository: ReferralProgramInfoRepository

    private let widgetSubject = CurrentValueSubject<FeedWidget?, Never>(nil)
    private weak var router: FeedWidgetsRoutable?

    private var wallet: UserWalletModel?
    private var info: ReferralProgramInfo?
    private var requestedWalletIds: Set<UserWalletId> = []
    private var failedWalletIds: Set<UserWalletId> = []
    private var hasRefreshed = false
    private var bag = Set<AnyCancellable>()
    private var walletBag = Set<AnyCancellable>()

    init(router: FeedWidgetsRoutable) {
        self.router = router

        bind()
    }
}

// MARK: - FeedWidgetProvider

extension ReferralWidgetProvider: FeedWidgetProvider {
    var widgetPublisher: AnyPublisher<FeedWidget?, Never> {
        widgetSubject.eraseToAnyPublisher()
    }

    func refresh() {
        hasRefreshed = true

        guard let walletId = wallet?.userWalletId, requestedWalletIds.insert(walletId).inserted else {
            return
        }

        failedWalletIds.remove(walletId)
        resolveWidget()

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

    func select() {
        guard let wallet else { return }

        router?.openReferral(wallet: wallet)
    }
}

// MARK: - Private

private extension ReferralWidgetProvider {
    func bind() {
        userWalletRepository.selectedUnlockedModelPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, wallet in provider.bindWallet(wallet) }
            .store(in: &bag)
    }

    func bindWallet(_ wallet: UserWalletModel?) {
        walletBag.removeAll()
        self.wallet = wallet.flatMap { $0.config.hasFeature(.referralProgram) ? $0 : nil }

        guard let wallet = self.wallet else {
            info = nil
            resolveWidget()
            return
        }

        referralProgramInfoRepository.infoPublisher(for: wallet.userWalletId)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, info in
                provider.info = info
                provider.resolveWidget()
            }
            .store(in: &walletBag)

        if hasRefreshed {
            refresh()
        }
    }

    func resolveWidget() {
        let widget: FeedWidget? = if let wallet, let reward = Self.makeReward(info: info, config: wallet.config) {
            .referFriend(reward: .success(reward))
        } else if let wallet, info == nil {
            .referFriend(reward: failedWalletIds.contains(wallet.userWalletId) ? .failure(FeedWidget.LoadError()) : .loading)
        } else {
            nil
        }

        guard widgetSubject.value != widget else {
            return
        }

        widgetSubject.send(widget)
    }

    static func makeReward(info: ReferralProgramInfo?, config: UserWalletConfig) -> String? {
        guard let info, info.referral == nil,
              let award = info.conditions.awards.first,
              config.supportedBlockchains.contains(where: { $0.networkId == award.token.networkId }),
              award.token.storageToken != nil, award.amount > 0 else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = Constants.rewardMaximumFractionDigits
        guard let amount = formatter.string(from: award.amount as NSDecimalNumber) else { return nil }

        return "\(amount) \(award.token.symbol)"
    }
}

// MARK: - Constants

private extension ReferralWidgetProvider {
    enum Constants {
        static let rewardMaximumFractionDigits = 8
    }
}
