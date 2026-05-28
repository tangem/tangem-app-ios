//
//  CommonPromotionRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemAssets
import TangemFoundation
import TangemNFT
import TangemPay
import Testing
@testable import Tangem

@Suite("CommonPromotionRepository")
final class CommonPromotionRepositoryTests {
    private let walletId = UserWalletId(value: Data([0x01, 0x02, 0x03, 0x04]))

    // MARK: - New Placements

    @Test("Returns promotions for tokenDetails placement")
    func returnsTokenDetailsPromotions() async throws {
        let sut = try await makeSUT(items: [makeItem(id: 123, placeholder: .tokenDetails)])
        let promotions = try await getPromotions(from: sut, placeholder: .tokenDetails)

        #expect(promotions.count == 1)
        #expect(promotions.first?.id == 123)
    }

    @Test("Returns promotions for yield placement")
    func returnsYieldPromotions() async throws {
        let sut = try await makeSUT(items: [makeItem(id: 456, placeholder: .yield)])
        let promotions = try await getPromotions(from: sut, placeholder: .yield)

        #expect(promotions.count == 1)
        #expect(promotions.first?.id == 456)
    }

    // MARK: - Token Info

    @Test("Promotion contains token info")
    func promotionContainsTokenInfo() async throws {
        let token = makeToken(networkId: "ethereum", symbol: "ETH", address: "0x0")
        let sut = try await makeSUT(items: [makeItem(id: 789, placeholder: .tokenDetails, tokens: [token])])
        let result = try await getPromotions(from: sut, placeholder: .tokenDetails).first?.tokens?.first

        #expect(result?.networkId == "ethereum")
        #expect(result?.token.symbol == "ETH")
    }

    // MARK: - Refresh Specific Placement

    @Test("Refreshes only specific placement, not all")
    func refreshesOnlySpecificPlacement() async throws {
        let spy = PromotionProviderSpy()
        let sut = try await makeSUT(provider: spy)
        spy.clearCalls()

        await sut.loadPromotions(userWalletId: walletId, placeholder: .tokenDetails)

        #expect(spy.loadPromotionsCalls.count == 1)
        #expect(spy.loadPromotionsCalls.first?.placeholder == .tokenDetails)
    }
}

// MARK: - Helpers

private extension CommonPromotionRepositoryTests {
    func makeSUT(items: [PromotionsDTO.Load.Item]) async throws -> CommonPromotionRepository {
        try await makeSUT(provider: PromotionProviderStub(items: items))
    }

    func makeSUT(provider: PromotionProvider) async throws -> CommonPromotionRepository {
        InjectedValues[\.userWalletRepository] = UserWalletRepositoryStub(walletId: walletId)
        InjectedValues[\.promotionProvider] = provider
        let sut = CommonPromotionRepository()
        try await Task.sleep(for: .milliseconds(50))
        return sut
    }

    func getPromotions(
        from sut: CommonPromotionRepository,
        placeholder: PromotionsDTO.Placement
    ) async throws -> [Promotion] {
        try await sut
            .promotionsPublisher(userWalletId: walletId, placeholder: placeholder)
            .first()
            .async()
    }

    func makeItem(
        id: Int,
        placeholder: PromotionsDTO.Placement,
        tokens: [PromotionsDTO.Load.TokenInfo]? = nil
    ) -> PromotionsDTO.Load.Item {
        .init(
            id: id,
            placeholder: placeholder,
            priority: "high",
            title: "T",
            subtitle: "S",
            iconUrl: nil,
            deeplink: nil,
            buttonEnabled: true,
            buttonText: "B",
            dismissable: true,
            tokens: tokens
        )
    }

    func makeToken(networkId: String, symbol: String = "TKN", address: String) -> PromotionsDTO.Load.TokenInfo {
        .init(
            networkId: networkId,
            token: .init(id: networkId, symbol: symbol, name: symbol, address: address, decimalCount: 18)
        )
    }
}

// MARK: - Test Doubles

private final class PromotionProviderStub: PromotionProvider {
    private let items: [PromotionsDTO.Load.Item]

    init(items: [PromotionsDTO.Load.Item]) {
        self.items = items
    }

    func loadPromotions(request: PromotionsDTO.Load.Request) async throws -> PromotionsDTO.Load.Response {
        .init(items: items)
    }

    func hidePromotion(request: PromotionsDTO.Hide.Request) async throws -> PromotionsDTO.Hide.Response {
        .init(displayId: request.displayId, walletId: request.walletId, status: .dismissed)
    }
}

private final class PromotionProviderSpy: PromotionProvider {
    private(set) var loadPromotionsCalls: [PromotionsDTO.Load.Request] = []

    func clearCalls() {
        loadPromotionsCalls.removeAll()
    }

    func loadPromotions(request: PromotionsDTO.Load.Request) async throws -> PromotionsDTO.Load.Response {
        loadPromotionsCalls.append(request)
        return .init(items: [])
    }

    func hidePromotion(request: PromotionsDTO.Hide.Request) async throws -> PromotionsDTO.Hide.Response {
        .init(displayId: request.displayId, walletId: request.walletId, status: .dismissed)
    }
}

private final class UserWalletRepositoryStub: UserWalletRepository {
    var shouldLockOnBackground: Bool { false }
    var isLocked: Bool { false }
    var models: [UserWalletModel] { [] }
    var selectedModel: UserWalletModel?
    var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> { Empty().eraseToAnyPublisher() }

    init(walletId: UserWalletId) {
        selectedModel = UserWalletModelStub(userWalletId: walletId)
    }

    func initialize() async {}
    func lock() {}
    func unlock(with method: UserWalletRepositoryUnlockMethod) async throws -> UserWalletModel { fatalError() }
    func select(userWalletId: UserWalletId) {}
    func updateAssociatedCard(userWalletId: UserWalletId, cardId: String) {}
    func add(userWalletModel: UserWalletModel) throws {}
    func delete(userWalletId: UserWalletId) {}
    func reorder(orderedUserWalletIds: [UserWalletId]) {}
    func onBiometricsChanged(enabled: Bool) {}
    func onSaveUserWalletsChanged(enabled: Bool) {}
    func savePublicData() {}
    func save(userWalletModel: UserWalletModel) {}
}

private final class UserWalletModelStub: UserWalletModel {
    let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }

    var hasBackupCards: Bool { false }
    var config: UserWalletConfig { fatalError() }
    var tangemApiAuthData: TangemApiAuthorizationData? { nil }
    var keysRepository: KeysRepository { fatalError() }
    var refcodeProvider: RefcodeProvider? { nil }
    var signer: TangemSigner { fatalError() }
    var updatePublisher: AnyPublisher<UpdateResult, Never> { Empty().eraseToAnyPublisher() }
    var backupInput: OnboardingInput? { nil }
    var nftManager: NFTManager { fatalError() }
    var walletImageProvider: WalletImageProviding { fatalError() }
    var accountModelsManager: AccountModelsManager { fatalError() }
    var userTokensPushNotificationsManager: UserTokensPushNotificationsManager { fatalError() }
    var name: String { "" }
    var hasImportedWallets: Bool { false }
    var emailData: [EmailCollectedData] { [] }
    var isUserWalletLocked: Bool { false }
    var cardSetLabel: String { "" }
    var analyticsContextData: AnalyticsContextData { fatalError() }
    var wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider { fatalError() }
    var keysDerivingInteractor: any KeysDeriving { fatalError() }
    var tangemPayAuthorizingInteractor: TangemPayAuthorizing { fatalError() }
    var tangemPayAccountPublisher: AnyPublisher<TangemPayAccount?, Never> { Empty().eraseToAnyPublisher() }
    var tangemPayAccount: TangemPayAccount? { nil }
    var tokensCount: Int? { nil }
    var totalBalance: TotalBalanceState { .empty }
    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> { Empty().eraseToAnyPublisher() }
    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> { Empty().eraseToAnyPublisher() }
    var emailConfig: EmailConfig? { nil }

    func validate() -> Bool { true }
    func update(type: UpdateRequest) {}
    func addAssociatedCard(cardId: String) {}
    func dispose() {}
    func resolve(_ resolver: UserWalletModelUnlockerResolver) -> UserWalletModelUnlocker { fatalError() }
}
