//
//  CommonPromoCampaignWalletsProviderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("CommonPromoCampaignWalletsProvider", .serialized)
struct CommonPromoCampaignWalletsProviderTests {
    private let walletA = UserWalletId(value: Data([0xAA]))
    private let walletB = UserWalletId(value: Data([0xBB]))

    @Test("A card wallet info carries the card's batch, a mobile one carries none")
    func walletInfoIdentity() {
        let cardInfo = PreviewCard.tangemWalletBackuped.cardInfo
        let mobileInfo = MobileWalletInfo(hasMnemonicBackup: false, hasICloudBackup: false, hasSocialLogin: false, accessCodeStatus: .none, keys: [])

        #expect(WalletInfo.cardWallet(cardInfo).promoCampaignIdentity == .card(batchId: cardInfo.card.batchId))
        #expect(WalletInfo.mobileWallet(mobileInfo).promoCampaignIdentity == .mobile)
    }

    @Test("Every wallet that tells its identity is listed with it")
    func walletsCarryIdentity() async {
        let repository = EventUserWalletRepositoryStub(models: [
            IdentityUserWalletModelStub(userWalletId: walletA, identity: .card(batchId: "AF04")),
            IdentityUserWalletModelStub(userWalletId: walletB, identity: .mobile),
        ])

        await withUserWalletRepository(repository) {
            #expect(CommonPromoCampaignWalletsProvider().wallets == [
                PromoCampaignWallet(userWalletId: walletA, identity: .card(batchId: "AF04")),
                PromoCampaignWallet(userWalletId: walletB, identity: .mobile),
            ])
        }
    }

    @Test("A wallet model that cannot tell its promo identity is left out")
    func walletWithoutIdentityIsLeftOut() async {
        let model = FakeUserWalletModel(
            userWalletName: "Wallet",
            isUserWalletLocked: false,
            isDelayed: false,
            cardsCount: 1,
            userWalletId: walletA,
            walletManagers: [],
            config: UserWalletConfigStubs.walletV2Stub
        )

        await withUserWalletRepository(EventUserWalletRepositoryStub(models: [model])) {
            #expect(CommonPromoCampaignWalletsProvider().wallets.isEmpty)
        }
    }

    @Test("The publisher starts with the current wallets")
    func publisherStartsWithCurrentWallets() async {
        let repository = EventUserWalletRepositoryStub(models: [IdentityUserWalletModelStub(userWalletId: walletA, identity: .mobile)])

        let published = await record(repository) {}

        #expect(published == [[PromoCampaignWallet(userWalletId: walletA, identity: .mobile)]])
    }

    @Test("Adding and deleting a wallet each publish the new list")
    func insertAndDeletePublish() async {
        let modelA = IdentityUserWalletModelStub(userWalletId: walletA, identity: .mobile)
        let modelB = IdentityUserWalletModelStub(userWalletId: walletB, identity: .card(batchId: "AF04"))
        let repository = EventUserWalletRepositoryStub(models: [modelA])

        let published = await record(repository) {
            repository.models = [modelA, modelB]
            repository.emit(.inserted(userWalletId: walletB))
            repository.models = [modelB]
            repository.emit(.deleted(userWalletIds: [walletA], isRepositoryEmpty: false))
        }

        #expect(published.map { $0.map(\.userWalletId) } == [[walletA], [walletA, walletB], [walletB]])
    }

    @Test("Upgrading a mobile wallet to a card publishes its new identity")
    func upgradePublishesNewIdentity() async {
        let model = IdentityUserWalletModelStub(userWalletId: walletA, identity: .mobile)
        let repository = EventUserWalletRepositoryStub(models: [model])

        let published = await record(repository) {
            model.changeIdentity(to: .card(batchId: "AF04"))
        }

        #expect(published.map { $0.map(\.identity) } == [[.mobile], [.card(batchId: "AF04")]])
    }

    @Test("Events and updates that leave the wallets as they are publish nothing new")
    func unchangedWalletsAreNotRepublished() async {
        let modelA = IdentityUserWalletModelStub(userWalletId: walletA, identity: .mobile)
        let modelB = IdentityUserWalletModelStub(userWalletId: walletB, identity: .card(batchId: "AF04"))
        let repository = EventUserWalletRepositoryStub(models: [modelA, modelB])

        let published = await record(repository) {
            repository.emit(.selected(userWalletId: walletB))
            repository.models = [modelB, modelA]
            repository.emit(.reordered(orderedUserWalletIds: [walletB, walletA]))
            repository.emit(.unlockedWallet(userWalletId: walletA))
            repository.emit(.unlocked)
            modelA.rename()
        }

        #expect(published.count == 1)
    }
}

// MARK: - Support

private extension CommonPromoCampaignWalletsProviderTests {
    func record(_ repository: EventUserWalletRepositoryStub, actions: () -> Void) async -> [[PromoCampaignWallet]] {
        var published: [[PromoCampaignWallet]] = []

        await withUserWalletRepository(repository) {
            let subscription = CommonPromoCampaignWalletsProvider().walletsPublisher.sink { published.append($0) }
            actions()
            subscription.cancel()
        }

        return published
    }

    func withUserWalletRepository(_ userWalletRepository: UserWalletRepository, operation: () async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousUserWalletRepository = InjectedValues[\.userWalletRepository]
            InjectedValues[\.userWalletRepository] = userWalletRepository

            defer {
                InjectedValues[\.userWalletRepository] = previousUserWalletRepository
            }

            await operation()
        }
    }
}

private final class EventUserWalletRepositoryStub: FakeUserWalletRepository {
    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    override var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func emit(_ event: UserWalletRepositoryEvent) {
        eventSubject.send(event)
    }
}

private final class IdentityUserWalletModelStub: FakeUserWalletModel, PromoCampaignIdentityProviding {
    private(set) var promoCampaignIdentity: PromoCampaignIdentity
    private let updateSubject = PassthroughSubject<UpdateResult, Never>()

    override var updatePublisher: AnyPublisher<UpdateResult, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    init(userWalletId: UserWalletId, identity: PromoCampaignIdentity) {
        promoCampaignIdentity = identity

        super.init(
            userWalletName: "Wallet",
            isUserWalletLocked: false,
            isDelayed: false,
            cardsCount: 1,
            userWalletId: userWalletId,
            walletManagers: [],
            config: UserWalletConfigStubs.walletV2Stub
        )
    }

    func changeIdentity(to identity: PromoCampaignIdentity) {
        promoCampaignIdentity = identity
        updateSubject.send(.configurationChanged(model: self))
    }

    func rename() {
        updateSubject.send(.nameDidChange(name: "Renamed"))
    }
}
