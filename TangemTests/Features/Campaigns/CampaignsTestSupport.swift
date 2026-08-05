//
//  CampaignsTestSupport.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import TangemPay
import Testing
@testable import Tangem

/// Use this tag for all campaign-sheet suites: @Suite(.tags(.campaigns))
extension Tag {
    @Tag static var campaigns: Self
}

/// Records navigation calls made by campaign view models.
final class CampaignRoutableSpy: CampaignRoutable {
    private struct State {
        var closeCampaignCallCount = 0
        var openedLearnMoreURLs: [URL] = []
        var errorToastTexts: [String] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    var closeCampaignCallCount: Int {
        state.withLock { $0.closeCampaignCallCount }
    }

    var openedLearnMoreURLs: [URL] {
        state.withLock { $0.openedLearnMoreURLs }
    }

    var errorToastTexts: [String] {
        state.withLock { $0.errorToastTexts }
    }

    func closeCampaign() {
        state.withLock { $0.closeCampaignCallCount += 1 }
    }

    func openLearnMore(url: URL) {
        state.withLock { $0.openedLearnMoreURLs.append(url) }
    }

    func presentErrorToast(with text: String) {
        state.withLock { $0.errorToastTexts.append(text) }
    }
}

/// Canned wallet identity, lock state, config, and tokens on top of the shared `UserWalletModelMock`,
/// with the mock's `fatalError` members stubbed out.
final class CampaignUserWalletModelStub: UserWalletModelMock {
    private let id: UserWalletId
    private let isLocked: Bool
    private let stubbedConfig: UserWalletConfig
    private let userTokensManager: UserTokensManager

    init(
        walletIdSeed: String,
        isLocked: Bool = false,
        config: UserWalletConfig = UserWalletConfigStub(),
        userTokensManager: UserTokensManager = UserTokensManagerMock()
    ) {
        id = UserWalletId(value: Data(walletIdSeed.utf8))
        self.isLocked = isLocked
        stubbedConfig = config
        self.userTokensManager = userTokensManager
    }

    override var userWalletId: UserWalletId { id }
    override var isUserWalletLocked: Bool { isLocked }
    override var config: UserWalletConfig { stubbedConfig }
    override var signer: TangemSigner { TangemSignerStub() }
    override var accountModelsManager: AccountModelsManager {
        AccountModelsManagerStub(
            account: CryptoAccountModelMock(
                isMainAccount: true,
                userTokensManager: userTokensManager,
                onArchive: { _ in }
            )
        )
    }
}

/// Serves a single canned crypto account.
final class AccountModelsManagerStub: AccountModelsManager {
    private let account: any CryptoAccountModel

    init(account: any CryptoAccountModel) {
        self.account = account
    }

    var canAddCryptoAccounts: Bool { false }
    var hasArchivedCryptoAccountsPublisher: AnyPublisher<Bool, Never> { .just(output: false) }
    var hasSyncedWithRemotePublisher: AnyPublisher<Bool, Never> { .just(output: true) }
    var accountModels: [AccountModel] { [.standard(.single(account))] }
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> { .just(output: accountModels) }
    var totalCryptoAccountsCountPublisher: AnyPublisher<Int, Never> { .just(output: 1) }

    func addCryptoAccount(name: String, icon: AccountModel.CompositeIcon) async throws(AccountEditError) -> AccountOperationResult {
        throw .tooManyAccounts
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        []
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountRecoveryError) -> AccountOperationResult {
        throw .tooManyAccounts
    }

    func acceptTangemPayOffer(authorizingInteractor: TangemPayAuthorizing) async {}
    func reorder(orderedIdentifiers: [any AccountModelPersistentIdentifierConvertible]) async throws {}
    func dispose() {}
}

/// Swaps the API service, the shared promotions repository (empty cache per test),
/// and the user wallet repository for campaign suites.
func withInjectedCampaignDependencies(
    _ apiService: TangemApiService,
    userWalletRepository: UserWalletRepository = FakeUserWalletRepository(models: []),
    operation: () async throws -> Void
) async rethrows {
    try await InjectedDependenciesIsolation.shared.run {
        let previousApiService = InjectedValues[\.tangemApiService]
        let previousRepository = InjectedValues[\.promotionCampaignsRepository]
        let previousUserWalletRepository = InjectedValues[\.userWalletRepository]
        InjectedValues[\.tangemApiService] = apiService
        InjectedValues[\.promotionCampaignsRepository] = PromotionCampaignsRepository()
        InjectedValues[\.userWalletRepository] = userWalletRepository
        defer {
            InjectedValues[\.tangemApiService] = previousApiService
            InjectedValues[\.promotionCampaignsRepository] = previousRepository
            InjectedValues[\.userWalletRepository] = previousUserWalletRepository
        }
        try await operation()
    }
}

enum CampaignsFixtures {
    static let usdcOnEthereum: TokenItem = .token(
        .init(
            name: "USD Coin",
            symbol: "USDC",
            contractAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
            decimalCount: 6,
            id: "usd-coin"
        ),
        .init(.ethereum(testnet: false), derivationPath: nil)
    )

    static func makeTokenSelectorItem(
        tokenItem: TokenItem = usdcOnEthereum,
        addressString: String = "0xUserAddress"
    ) -> TokenSelectorItem {
        let walletModel = WalletModelTestsMock(
            tokenItem: tokenItem,
            isEmpty: false,
            addresses: [PlainAddress(value: addressString, type: .default)]
        )

        let userWalletInfo = UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: UserWalletConfigStub(),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )

        return TokenSelectorItem(
            userWalletInfo: userWalletInfo,
            kind: .crypto(walletModel, CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in }))
        )
    }

    static func makeBannerData(
        tokens: [BannerPromotion.Response.Token] = [PromotionCampaignsFixtures.makeToken()],
        start: Date = Date().addingTimeInterval(-.day),
        end: Date = Date().addingTimeInterval(.day),
        status: BannerPromotion.Response.Status = .active,
        link: String? = "https://tangem.com/promo"
    ) -> CampaignBannerData {
        CampaignBannerData(
            eligibleTokens: tokens,
            startDate: start,
            endDate: end,
            campaignStatus: status,
            link: link
        )
    }
}

private extension TimeInterval {
    static let day: TimeInterval = 86400
}
