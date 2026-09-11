//
//  ExpressProviderStubs.swift
//  TangemTests
//
//  Created for [REDACTED_INFO].
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
@testable import TangemExpress
@testable import Tangem

final class ExpressProviderManagerStub: ExpressProviderManager {
    private let state: ExpressProviderManagerState

    init(state: ExpressProviderManagerState) {
        self.state = state
    }

    func getState() -> ExpressProviderManagerState { state }
    func reset() {}
    func update(request: ExpressManagerSwappingPairRequest) async {}

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        fatalError("Not used in tests")
    }
}

struct ExpressWalletDummy: ExpressSourceWallet {
    var walletInfo: ExpressWalletInfo { ExpressWalletInfo(id: "stub", refcode: nil) }
    var currency: ExpressWalletCurrency { fatalError("Not used in tests") }
    var coinCurrency: ExpressWalletCurrency { fatalError("Not used in tests") }
    var address: String? { nil }
    var extraId: String? { nil }

    var allowanceProvider: AllowanceProvider? { nil }
    var yieldModuleTransactionHelper: YieldModuleTransactionHelper? { nil }
    var balanceProvider: BalanceProvider { fatalError("Not used in tests") }
    var analyticsLogger: AnalyticsLogger { fatalError("Not used in tests") }
    var providerTransactionValidator: ExpressProviderTransactionValidator { fatalError("Not used in tests") }
    var operationType: ExpressOperationType { fatalError("Not used in tests") }
    var supportedProvidersFilter: SupportedProvidersFilter { fatalError("Not used in tests") }
    var expressFeeProviderFactory: ExpressFeeProviderFactory { fatalError("Not used in tests") }
}

struct ExpressFeeProviderDummy: ExpressFeeProvider {
    var supportsGasBasedFeeEstimate: Bool { fatalError("Not used in tests") }

    func feeCurrency() -> ExpressWalletCurrency { fatalError("Not used in tests") }
    func feeCurrencyBalance() throws -> Decimal { fatalError("Not used in tests") }
    func estimatedFee(amount: Decimal) async throws -> BSDKFee { fatalError("Not used in tests") }
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee { fatalError("Not used in tests") }
    func transactionFee(approveData: BSDKApproveTransactionData) async throws -> BSDKFee { fatalError("Not used in tests") }
    func transactionFee(data: ExpressTransactionDataType) async throws -> BSDKFee { fatalError("Not used in tests") }
    func transactionFee(data: ExpressTransactionDataType, allowanceOverride: AllowanceOverride, approveData: BSDKApproveTransactionData) async throws -> ApproveWithSwapFee { fatalError("Not used in tests") }
    func revokeAndApproveTransactionFee(revokeData: BSDKApproveTransactionData) async throws -> RevokeAndApproveFee { fatalError("Not used in tests") }
}

enum ExpressAvailableProviderFixture {
    /// Builds a provider whose state maps to a loaded swap state, so a test can drive `SwapModel` into the
    /// states that arm autoupdating.
    static func make(state: ExpressProviderManagerState) -> ExpressAvailableProvider {
        let provider = ExpressProvider(
            id: "provider",
            name: "Provider",
            type: .cex,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        )

        let context = ExpressProviderFlowContext(
            provider: provider,
            pair: ExpressManagerSwappingPair(source: ExpressWalletDummy(), destination: ExpressWalletDummy()),
            rateType: .float,
            expressFeeProvider: ExpressFeeProviderDummy(),
            expressAPIProvider: ExpressAPIProviderStub(),
            mapper: ExpressManagerMapper(),
            featureFlags: ExpressFeatureFlags()
        )

        return ExpressAvailableProvider(context: context, manager: ExpressProviderManagerStub(state: state))
    }
}
