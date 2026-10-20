//
//  TangemPayStateCachingUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayStateCachingUITests: BaseTestCase {
    private static let sessionScenario = "tangem_pay_session"
    private static let balanceScenario = "tangem_pay_balance_update"
    private static let historyScenario = "tangem_pay_transaction_history"
    private static let sessionExpiredState = "SessionExpired"
    private static let serviceUnavailableState = "ServiceUnavailable"
    private static let cachedBalance = "$10.00"
    private static let cardMask = "*4242"
    private static let cachedTransaction = "Tangem Coffee"

    func testMainScreenShowsCachedData_WhenSessionExpired() {
        setAllureId(9753)

        warmUpCacheAndRelaunch(sessionState: Self.sessionExpiredState)
            .verifyTangemPayTileCachedIcon()
            .verifyTangemPayTileSubtitle(contains: Self.cardMask)
            .verifyTangemPayTileBalanceContains(Self.cachedBalance)
            .verifySessionExpiredBannerHidden()
    }

    func testMainScreenShowsCachedData_WhenServiceUnavailable() {
        setAllureId(9754)

        warmUpCacheAndRelaunch(sessionState: Self.serviceUnavailableState)
            .verifyTangemPayTileCachedIcon()
            .verifyTangemPayTileSubtitle(contains: Self.cardMask)
            .verifyTangemPayTileBalanceContains(Self.cachedBalance)
            .verifyConnectionIssuesBannerHidden()
    }

    func testPaymentAccountShowsSessionExpiredBanner_WhenSessionExpired() {
        setAllureId(9755)

        warmUpCacheAndRelaunch(sessionState: Self.sessionExpiredState)
            .openTangemPay()
            .waitForScreen()
            .verifySessionExpiredBanner()
            .verifyRenewSessionButton()
            .verifyStaleState(cachedBalance: Self.cachedBalance)
            .verifyTransactionRow(name: Self.cachedTransaction)
    }

    func testPaymentAccountShowsConnectionIssuesBanner_WhenServiceUnavailable() {
        setAllureId(9756)

        warmUpCacheAndRelaunch(sessionState: Self.serviceUnavailableState)
            .openTangemPay()
            .waitForScreen()
            .verifyConnectionIssuesBanner()
            .verifyStaleState(cachedBalance: Self.cachedBalance)
            .verifyTransactionRow(name: Self.cachedTransaction)
    }

    func testMainScreenShowsSessionExpired_WhenCacheIsEmpty() {
        setAllureId(9757)

        launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: Self.sessionScenario, initialState: Self.sessionExpiredState)]
        )
        .verifyTangemPayTileExists()
        .verifyTangemPayTileSubtitle(contains: Localization.commonSessionExpired)
        .verifyTangemPayTileHasNoBalance()
        .verifySessionExpiredBanner()
        .verifyRenewSessionButton()
    }

    func testMainScreenKeepsCachedKycInProgress_WhenCustomerRequestFails() {
        setAllureId(9586)

        launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: Constants.Scenario.kycStatus, initialState: Constants.State.kycInProgress)]
        )
        .verifyTangemPayTileShowsKycInProgress()
        .openTangemPayKycStatusSheet()
        .waitForSheet()
        .close()
        .verifyTangemPayTileShowsKycInProgress()

        relaunchKeepingState(scenarios: [
            ScenarioConfig(name: Constants.Scenario.kycStatus, initialState: Constants.State.kycInProgress),
            ScenarioConfig(name: Self.sessionScenario, initialState: Self.serviceUnavailableState),
        ])
        .verifyTangemPayTileShowsKycInProgress()
        .verifyTangemPayTileCachedIcon()
        .verifyTangemPayTileSubtitle(doesNotContain: Localization.tangempayIssuingYourCard)
        .verifyTangemPayTileHasNoBalance()
    }

    /// [REDACTED_INFO] Main total balance drops the cached Payment account balance and shows no outdated-balance notice when Tangem Pay customer requests fail
    func skipped_testMainScreenShowsCachedTotalBalanceAndOutdatedNotice_WhenCustomerRequestsFail() {
        setAllureId(9692)

        let cachedTotalBalance = launchAndImportHotWallet(
            scenarios: [ScenarioConfig(name: Self.balanceScenario, initialState: Constants.State.initialBalance)]
        )
        .verifyTangemPayTileBalanceContains(Self.cachedBalance)
        .waitForTotalBalanceIncludingTangemPay(tokenNames: Constants.tokenNames)

        relaunchKeepingState(scenarios: [ScenarioConfig(name: Self.sessionScenario, initialState: Self.serviceUnavailableState)])
            .verifyTangemPayTileCachedIcon()
            .verifyTangemPayTileBalanceContains(Self.cachedBalance)
            .verifyOutdatedBalancesNotice()
            .verifyTotalBalanceRemains(cachedTotalBalance)
    }

    private func warmUpCacheAndRelaunch(sessionState: String) -> MainScreen {
        launchAndImportHotWallet(
            scenarios: [
                ScenarioConfig(name: Self.balanceScenario, initialState: "InitialBalance"),
                ScenarioConfig(name: Self.historyScenario, initialState: "SpendCompleted"),
            ]
        )
        .openTangemPay()
        .waitForScreen()
        .verifyBalanceContains(Self.cachedBalance)
        .verifyTransactionRow(name: Self.cachedTransaction)

        // The session scenario also fails /customer/balance, so the restarted app can only show cached values.
        return relaunchKeepingState(scenarios: [
            ScenarioConfig(name: Self.sessionScenario, initialState: sessionState),
            ScenarioConfig(name: Self.historyScenario, initialState: "HistoryError"),
        ])
    }
}

private extension TangemPayStateCachingUITests {
    enum Constants {
        static let tokenNames = ["Bitcoin", "Ethereum", "Polygon", "POL (ex-MATIC)"]

        enum Scenario {
            static let kycStatus = "tangem_pay_kyc_status"
        }

        enum State {
            static let kycInProgress = "InProgress"
            static let initialBalance = "InitialBalance"
        }
    }
}
