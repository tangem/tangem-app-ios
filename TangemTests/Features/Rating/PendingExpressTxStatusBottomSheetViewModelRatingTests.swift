//
//  PendingExpressTxStatusBottomSheetViewModelRatingTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemAssets
import TangemFoundation
import TangemSdk
import TangemTestKit
import TangemUI
import Testing
@testable import Tangem

@Suite("PendingExpressTxStatusBottomSheetViewModel Rating", .serialized)
@MainActor
final class PendingExpressTxStatusBottomSheetViewModelRatingTests: LeakTrackingTestSuite {
    typealias SUT = PendingExpressTxStatusBottomSheetViewModel

    override init() {
        super.init()
        InjectedValues[\.keysManager] = StubKeysManager()
    }

    @Test("ratingViewModel is nil when externalTxId is nil")
    func ratingViewModelNilWithoutExternalTxId() {
        let (sut, _) = makeSUT(externalTxId: nil)

        #expect(sut.ratingViewModel == nil)
    }

    @Test("ratingViewModel created after transaction updates with externalTxId")
    func ratingViewModelCreatedOnUpdate() async throws {
        let (sut, subject) = makeSUT(externalTxId: nil)

        await sendUpdate(to: subject, externalTxId: anyExternalID)

        _ = try #require(sut.ratingViewModel)
    }

    @Test("ratingViewModel created only once")
    func ratingViewModelCreatedOnlyOnce() async throws {
        let (sut, subject) = makeSUT(externalTxId: anyExternalID)

        let firstInstance = try #require(sut.ratingViewModel)

        await sendUpdate(to: subject, externalTxId: anyExternalID)

        #expect(sut.ratingViewModel === firstInstance)
    }

    @Test("ratingViewModel publishes changes")
    func ratingViewModelPublishesChanges() async throws {
        let (sut, subject) = makeSUT(externalTxId: nil)

        var receivedValues: [RatingViewModel?] = []
        let cancellable = sut.$ratingViewModel.sink { receivedValues.append($0) }

        await sendUpdate(to: subject, externalTxId: anyExternalID)

        #expect(receivedValues.count >= 2)
        let lastValue = try #require(receivedValues.last)
        _ = try #require(lastValue)

        cancellable.cancel()
    }
}

// MARK: - Helpers

private extension PendingExpressTxStatusBottomSheetViewModelRatingTests {
    var anyExternalID: String { "external_123" }

    func sendUpdate(
        to subject: CurrentValueSubject<[PendingTransaction], Never>,
        externalTxId: String
    ) async {
        subject.send([makePendingTransaction(externalTxId: externalTxId)])
        // Allow Combine pipeline to process the update on main queue
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }

    func makeSUT(
        expressTransactionId: String = "express_tx_1",
        externalTxId: String? = nil
    ) -> (sut: SUT, subject: CurrentValueSubject<[PendingTransaction], Never>) {
        let tx = makePendingTransaction(expressTransactionId: expressTransactionId, externalTxId: externalTxId)
        let subject = CurrentValueSubject<[PendingTransaction], Never>([tx])
        let manager = StubPendingExpressTransactionsManager(subject: subject)

        let sut = SUT(
            pendingTransaction: tx,
            currentTokenItem: makeTokenItem(),
            userWalletInfo: makeUserWalletInfo(),
            pendingTransactionsManager: manager,
            router: StubRouter(),
            isRatingFeatureAvailable: true
        )

        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(subject)
        trackForMemoryLeaks(manager)

        return (sut, subject)
    }

    func makePendingTransaction(
        expressTransactionId: String = "express_tx_1",
        externalTxId: String? = nil
    ) -> PendingTransaction {
        let tokenItem = makeTokenItem()
        let tokenTxInfo = ExpressPendingTransactionRecord.TokenTxInfo(
            userWalletId: "test_wallet_id",
            tokenItem: tokenItem,
            address: "0x123",
            amountString: "100",
            isCustom: false
        )

        let provider = ExpressPendingTransactionRecord.Provider(
            id: "test_provider",
            name: "Test Provider",
            iconURL: nil,
            type: .cex
        )

        return PendingTransaction(
            type: .swap(source: tokenTxInfo, destination: tokenTxInfo),
            expressTransactionId: expressTransactionId,
            externalTxId: externalTxId,
            externalTxURL: externalTxId.map { "https://example.com/tx/\($0)" },
            provider: provider,
            date: Date(),
            transactionStatus: .awaitingDeposit,
            refundedTokenItem: nil,
            statuses: [.awaitingDeposit],
            averageDuration: nil,
            createdAt: nil
        )
    }

    func makeTokenItem() -> TokenItem {
        .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    }

    func makeUserWalletInfo() -> UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01, 0x02, 0x03])),
            config: StubUserWalletConfig(),
            refcode: nil,
            signer: StubTangemSigner(),
            emailDataProvider: StubEmailDataProvider()
        )
    }
}

// MARK: - Stubs

private final class StubPendingExpressTransactionsManager: PendingExpressTransactionsManager {
    private let subject: CurrentValueSubject<[PendingTransaction], Never>

    var pendingTransactions: [PendingTransaction] { subject.value }
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransaction], Never> { subject.eraseToAnyPublisher() }

    init(subject: CurrentValueSubject<[PendingTransaction], Never>) {
        self.subject = subject
    }

    func hideTransaction(with id: String) {}
}

private final class StubRouter: PendingExpressTxStatusRoutable {
    func openURL(_ url: URL) {}
    func openRefundCurrency(walletModel: any WalletModel, userWalletModel: UserWalletModel) {}
    func dismissPendingTxSheet() {}
}

private final class StubTangemSigner: TangemSigner {
    var hasNFCInteraction: Bool { false }
    var latestSignerType: TangemSignerType? { nil }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        Fail(error: NSError(domain: "stub", code: 0)).eraseToAnyPublisher()
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, any Error> {
        Fail(error: NSError(domain: "stub", code: 0)).eraseToAnyPublisher()
    }

    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        Fail(error: NSError(domain: "stub", code: 0)).eraseToAnyPublisher()
    }
}

private final class StubEmailDataProvider: EmailDataProvider {
    var emailData: [EmailCollectedData] { [] }
    var emailConfig: EmailConfig? { nil }
}

private struct StubUserWalletConfig: UserWalletConfig {
    var cardsCount: Int { 1 }
    var cardSetLabel: String { "Test" }
    var defaultName: String { "Test" }
    var existingCurves: [EllipticCurve] { [] }
    var createWalletCurves: [EllipticCurve] { [] }
    var tangemSigner: TangemSigner { StubTangemSigner() }
    var generalNotificationEvents: [GeneralNotificationEvent] { [] }
    var isWalletsCreated: Bool { true }
    var supportedBlockchains: Set<Blockchain> { [] }
    var defaultBlockchains: [TokenItem] { [] }
    var persistentBlockchains: [TokenItem] { [] }
    var embeddedBlockchain: TokenItem? { nil }
    var emailData: [EmailCollectedData] { [] }
    var userWalletIdSeed: Data? { nil }
    var productType: Analytics.ProductType { .wallet }
    var cardHeaderImage: ImageType? { nil }
    var walletThumbnailType: ThumbnailWalletViewType? { nil }
    var cardSessionFilter: SessionFilter { .cardId("test") }
    var contextBuilder: WalletCreationContextBuilder { fatalError() }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability { .available }
    func makeAnyWalletManagerFactory() -> AnyWalletManagerFactory { fatalError() }
    func makeOnboardingStepsBuilder(backupService: BackupService) -> any OnboardingStepsBuilder { fatalError() }
    func makeBackupService() -> BackupService { fatalError() }
    func makeTangemSdk() -> TangemSdk { fatalError() }
    func makeMainHeaderProviderFactory() -> MainHeaderProviderFactory { fatalError() }
}

private struct StubKeysManager: KeysManager {
    var surveySparrow: SurveySparrowKeys {
        // Decode from JSON since SurveySparrowKeys only has Decodable init in prod
        let json = """
        {
            "domain": "test.surveysparrow.com",
            "apiKey": "test_token",
            "swapRating": {
                "surveyId": "1",
                "ratingQuestionId": "2",
                "feedbackQuestionId": "3"
            }
        }
        """
        return try! JSONDecoder().decode(SurveySparrowKeys.self, from: json.data(using: .utf8)!)
    }

    // MARK: - Unused properties (fatalError if accessed)

    var appsFlyer: AppsFlyerConfig { fatalError("Not used in tests") }
    var customerIO: CustomerIOKeys { fatalError("Not used in tests") }
    var moonPayKeys: MoonPayKeys { fatalError("Not used in tests") }
    var mercuryoWidgetId: String { fatalError("Not used in tests") }
    var mercuryoSecret: String { fatalError("Not used in tests") }
    var blockchainSdkKeysConfig: BlockchainSdkKeysConfig { fatalError("Not used in tests") }
    var tangemComAuthorization: String? { fatalError("Not used in tests") }
    var infuraProjectId: String { fatalError("Not used in tests") }
    var utorgSID: String { fatalError("Not used in tests") }
    var walletConnectProjectId: String { fatalError("Not used in tests") }
    var expressKeys: ExpressKeys { fatalError("Not used in tests") }
    var devExpressKeys: ExpressKeys? { fatalError("Not used in tests") }
    var stakeKitKey: String { fatalError("Not used in tests") }
    var moralisAPIKey: String { fatalError("Not used in tests") }
    var blockaidAPIKey: String { fatalError("Not used in tests") }
    var tangemApiKey: String { "test_api_key" }
    var tangemApiKeyDev: String { fatalError("Not used in tests") }
    var tangemApiKeyStage: String { fatalError("Not used in tests") }
    var amplitudeApiKey: String { fatalError("Not used in tests") }
    var appsFlyerConfig: AppsFlyerConfig { fatalError("Not used in tests") }
    var yieldModuleApiKey: String { fatalError("Not used in tests") }
    var yieldModuleApiKeyDev: String { fatalError("Not used in tests") }
    var p2pApiKeys: P2PAPIKeys { fatalError("Not used in tests") }
    var bffStaticToken: String { fatalError("Not used in tests") }
    var bffStaticTokenDev: String { fatalError("Not used in tests") }
    var gaslessTxApiKey: String { fatalError("Not used in tests") }
    var gaslessTxApiKeyDev: String { fatalError("Not used in tests") }
}
