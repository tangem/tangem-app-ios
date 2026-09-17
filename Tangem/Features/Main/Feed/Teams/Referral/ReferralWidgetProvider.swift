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

    private let rewardSubject = CurrentValueSubject<String?, Never>(nil)
    private weak var router: FeedWidgetsRoutable?

    private var wallet: UserWalletModel?
    private var requestedWalletIds: Set<UserWalletId> = []
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
        rewardSubject
            .map { $0.map { FeedWidget.referFriend(reward: $0) } }
            .eraseToAnyPublisher()
    }

    func refresh() {
        hasRefreshed = true

        guard let walletId = wallet?.userWalletId, requestedWalletIds.insert(walletId).inserted else {
            return
        }

        runTask(in: self) { provider in
            do {
                _ = try await provider.referralProgramInfoRepository.loadInfo(for: walletId)
            } catch {
                await runOnMain { provider.requestedWalletIds.remove(walletId) }
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
            rewardSubject.send(nil)
            return
        }

        referralProgramInfoRepository.infoPublisher(for: wallet.userWalletId)
            .map { Self.makeReward(info: $0, config: wallet.config) }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { provider, reward in provider.rewardSubject.send(reward) }
            .store(in: &walletBag)

        if hasRefreshed {
            refresh()
        }
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
