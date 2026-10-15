//
//  TangemPayTariffPlansUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayTariffPlansUITests: BaseTestCase {
    func testComparePlans_DuringOnboarding_ShowsBothPlans() {
        setAllureId(10382)

        launchForOnboarding()
            .verifyTangemPayTileSubtitle(contains: Localization.tangempaySelectPlanTitle)
            .openTangemPaySelectPlan()
            .waitForScreen()
            .tapCompare()
            .waitForSheet(comparing: Constants.Plan.basic)
            .verifySection("Plan fee")
            .verifyPlanCompared(Constants.Plan.basic)
            .verifyPlanCompared(Constants.Plan.plus)
    }

    func testSelectBasicPlan_DuringOnboarding_IssuesBasicCard() {
        setAllureId(10375)

        let selectPlan = launchForOnboarding(balance: "AfterFullWithdraw")
            .openTangemPaySelectPlan()
            .waitForScreen()
            .verifyPlanName(Constants.Plan.basic)
            .verifyPlanDetail("$10,000 daily spending limit")
            .verifyPlanDetail("$0 / month")

        let ordersBefore = placeOrderRequestCount()
        stagePlanState("Basic")
        stageBasicOrderIssuing()
        let paymentAccount = selectPlan
            .tapSelectExpectingPlanActivation()
            .waitForScreen()
            .verifyIssuingCardBanner()
            .verifyWithdrawDisabled()
        assertOrdersPlaced(since: ordersBefore)

        completeBasicOrderIssuing()
        paymentAccount
            .waitForIssuingCardBannerHidden()
            .openMoreActionsMenu()
            .verifyCurrentPlanMenuItem()
            .tapCurrentPlanMenuItem()
            .waitForScreen()
            .verifyPlanName(Constants.Plan.basic)
    }

    func testSelectPlusPlan_DuringOnboarding_CanBeCancelledBeforePayment() {
        setAllureId(10376)

        let selectPlan = launchForOnboarding()
            .openTangemPaySelectPlan()
            .waitForScreen()
            .swipeToPlan(named: Constants.Plan.plus)
            .verifyPlanDetail("\(Constants.Plan.plusFee) / month")

        awaitPlanFeePayment(orders: "AwaitingDepositWithBasicFallback")
        let paymentAccount = selectPlan
            .tapSelectExpectingPlanActivation()
            .waitForScreen()
            .verifyInactiveBadge()
            .verifyAwaitingDepositBanner(contains: Constants.Plan.plusFee)

        let cancelsBefore = cancelOrderRequestCount()
        let ordersBefore = placeOrderRequestCount()
        let currentPlan = paymentAccount
            .openCurrentPlan()
            .waitForScreen()
            .verifyAwaitingDepositBanner(contains: Localization.tangempayCurrentPlanAwaitingDepositNotification(Constants.Plan.plus))
        stageBasicOrderPolling()
        currentPlan.tapCancelTransition()
        assertRequestSent(cancelOrderRequestCount, since: cancelsBefore, named: "order cancellation")

        currentPlan
            .waitForAwaitingDepositBannerHidden()
            .tapBack()
            .waitForAwaitingDepositBannerHidden()
            .verifyIssuingCardBanner()
        assertOrdersPlaced(since: ordersBefore)

        completeBasicOrderIssuing()
        paymentAccount
            .waitForIssuingCardBannerHidden()
    }

    func testSelectPlusPlan_DuringOnboarding_IssuesPlusCardAfterTopUp() {
        setAllureId(10377)

        let selectPlan = launchForOnboarding()
            .openTangemPaySelectPlan()
            .waitForScreen()
            .swipeToPlan(named: Constants.Plan.plus)

        awaitPlanFeePayment()
        let paymentAccount = selectPlan
            .tapSelectExpectingPlanActivation()
            .waitForScreen()
            .verifyAwaitingDepositBanner(contains: Constants.Plan.plusFee)
            .tapAwaitingDepositAddFunds()
            .waitForScreen()
            .verifySwapAndReceiveOptions()
            .close()

        wireMockClient.setScenarioStateSync(Constants.Scenario.balance, state: "AfterDeposit")
        stagePlusOrderIssuing()
        paymentAccount
            .waitForAwaitingDepositBannerHidden()
            .verifyIssuingCardBanner()

        completePlusOrderWithPlanFee()
        paymentAccount
            .waitForIssuingCardBannerHidden()
        pullToRefresh()
        paymentAccount
            .verifyTransactionVisible(merchantName: Constants.Transaction.planFee)
            .openMoreActionsMenu()
            .verifyCurrentPlanMenuItem()
            .tapCurrentPlanMenuItem()
            .waitForScreen()
            .verifyPlanName(Constants.Plan.plus)
    }

    func testComparePlans_WhenChangingPlan_ShowsBothPlans() {
        setAllureId(10383)

        launchWithPlan(state: "Basic", transitions: "FromBasic")
            .openTangemPay()
            .waitForScreen()
            .openMoreActionsMenu()
            .verifyMoreActionsMenuItems()
            .tapCurrentPlanMenuItem()
            .waitForScreen()
            .tapChangePlan()
            .waitForScreen()
            .tapCompare()
            .waitForSheet(comparing: Constants.Plan.basic)
            .verifySection("Max cards issued")
            .verifyPlanCompared(Constants.Plan.basic)
            .verifyPlanCompared(Constants.Plan.plus)
    }

    func testUpgradeToPlus_WithInsufficientBalance_ShowsTopUpBanner() {
        setAllureId(10378)

        let currentPlan = launchWithPlan(state: "Basic", transitions: "FromBasic", balance: "BelowIssueFee")
            .openTangemPay()
            .waitForScreen()
            .openMoreActionsMenu()
            .verifyMoreActionsMenuItems()
            .tapCurrentPlanMenuItem()
            .waitForScreen()

        let confirmPlan = currentPlan
            .verifyPlanName(Constants.Plan.basic)
            .verifySection(Localization.tangempayCurrentPlanSectionCard)
            .verifySection(Localization.tangempayCurrentPlanSectionPlan)
            .verifyPlanRow("Visa Programme", contains: "Platinum")
            .verifyPlanRow("Plan fee", contains: "$0.00")
            .verifyPlanRow("Max cards issued", contains: "3")
            .tapChangePlan()
            .waitForScreen()
            .verifyPlanName(Constants.Plan.plus)
            .tapSelectExpectingConfirmation()
            .waitForScreen()
            .verifyTitle(contains: Constants.Plan.plusProgram)
            .verifyPoint(contains: Localization.tangempaySelectPlanConfirmPointMonthlyFee(Constants.Plan.plusFee))

        awaitPlanFeePayment()
        let paymentAccount = confirmPlan
            .tapConfirm()
            .waitForScreen()
            .verifyAwaitingDepositBanner(contains: Constants.Plan.plusFee)

        wireMockClient.setScenarioStateSync(Constants.Scenario.balance, state: "AfterDeposit")
        stagePlusOrderIssuing()
        paymentAccount
            .waitForAwaitingDepositBannerHidden()
            .verifyIssuingCardBanner()

        completePlanOrder(planState: "Plus")
        paymentAccount
            .waitForIssuingCardBannerHidden()
    }

    func testUpgradeToPlus_WithSufficientBalance_IssuesPlusCard() {
        setAllureId(10380)

        let confirmPlan = launchWithPlan(state: "Basic", transitions: "FromBasic")
            .openTangemPay()
            .waitForScreen()
            .openMoreActionsMenu()
            .verifyMoreActionsMenuItems()
            .tapCurrentPlanMenuItem()
            .waitForScreen()
            .tapChangePlan()
            .waitForScreen()
            .verifyPlanName(Constants.Plan.plus)
            .tapSelectExpectingConfirmation()
            .waitForScreen()

        let ordersBefore = placeOrderRequestCount()
        stagePlusOrderIssuing()
        let paymentAccount = confirmPlan
            .tapConfirm()
            .waitForScreen()
            .verifyIssuingCardBanner()
        assertOrdersPlaced(since: ordersBefore)

        completePlusOrderWithPlanFee()
        paymentAccount
            .waitForIssuingCardBannerHidden()
        pullToRefresh()
        paymentAccount
            .verifyTransactionVisible(merchantName: Constants.Transaction.planFee)
            .openMoreActionsMenu()
            .verifyCurrentPlanMenuItem()
            .tapCurrentPlanMenuItem()
            .waitForScreen()
            .verifyPlanName(Constants.Plan.plus)
        assertOrdersPlaced(since: ordersBefore)
    }

    func testCancelUpgrade_WithInsufficientBalance_KeepsBasicPlan() {
        setAllureId(10411)

        let paymentAccount = launchWithPlan(
            state: "Basic",
            transitions: "FromBasic",
            balance: "BelowIssueFee",
            orders: "AwaitingDeposit",
            order: "AwaitingDeposit"
        )
        .openTangemPay()
        .waitForScreen()
        .verifyAwaitingDepositBanner(contains: Constants.Plan.plusFee)
        .verifyCardDisplayed(cardId: Constants.Card.id)

        let cancelsBefore = cancelOrderRequestCount()
        let currentPlan = paymentAccount
            .openCurrentPlan()
            .waitForScreen()
        currentPlan.tapCancelTransition()
        drainPlanOrders()
        assertRequestSent(cancelOrderRequestCount, since: cancelsBefore, named: "order cancellation")

        currentPlan
            .waitForAwaitingDepositBannerHidden()
            .tapBack()
            .waitForAwaitingDepositBannerHidden()
            .verifyCardDisplayed(cardId: Constants.Card.id)
            .openMoreActionsMenu()
            .verifyCurrentPlanMenuItem()
            .tapCurrentPlanMenuItem()
            .waitForScreen()
            .verifyPlanName(Constants.Plan.basic)
    }

    func testDowngradeToBasic_SchedulesPendingTransition() {
        setAllureId(10379)

        let confirmPlan = launchWithPlan(state: "Plus", transitions: "FromPlus")
            .openTangemPay()
            .waitForScreen()
            .openMoreActionsMenu()
            .verifyMoreActionsMenuItems()
            .tapCurrentPlanMenuItem()
            .waitForScreen()
            .verifyPlanName(Constants.Plan.plus)
            .verifyPlanRow("Visa Programme", contains: "Signature")
            .verifyPlanRow("Plan fee", contains: Constants.Plan.plusFee)
            .verifyPlanRow("Max cards issued", contains: "5")
            .tapChangePlan()
            .waitForScreen()
            .verifyPlanName(Constants.Plan.basic)
            .tapSelectExpectingConfirmation()
            .waitForScreen()
            .verifyTitle(contains: Constants.Plan.plus)
            .verifyPoint(contains: Localization.tangempaySelectPlanConfirmPointNoFee)

        let requestsBefore = pendingTransitionRequestCount()
        stagePlanState("DowngradePending")
        confirmPlan
            .tapConfirmExpectingCurrentPlan()
            .waitForScreen()
            .verifyDowngradeBanner(contains: Constants.Plan.basic)
        assertRequestSent(pendingTransitionRequestCount, since: requestsBefore, named: "pending transition")
    }

    func testStayOnPlus_CancelsThePendingDowngrade() {
        setAllureId(10381)

        let currentPlan = launchWithPlan(state: "DowngradePending", transitions: "FromPlus")
            .openTangemPay()
            .waitForScreen()
            .openMoreActionsMenu()
            .verifyMoreActionsMenuItems()
            .tapCurrentPlanMenuItem()
            .waitForScreen()
            .verifyDowngradeBanner(contains: Constants.Plan.basic)

        let requestsBefore = cancelPendingTransitionRequestCount()
        let staySheet = currentPlan
            .tapStayOnPlan()
            .waitForSheet()
            .verifyContent(title: Localization.tangempayCurrentPlanStaySheetTitle(Constants.Plan.plus), description: Localization.tangempayCurrentPlanStaySheetBody(Constants.Plan.basic))

        stagePlanState("Plus")
        staySheet
            .tapStay()
            .waitForScreen()
            .verifyFeeChargedBanner(contains: "\(Constants.Plan.plusFee) monthly fee will be charged")
        assertRequestSent(cancelPendingTransitionRequestCount, since: requestsBefore, named: "pending transition cancellation")
    }

    func testPlanDetails_DuringActiveTransition_StayReachable() {
        setAllureId(10409)

        launchWithPlan(state: "Transitioning", transitions: "FromBasic")
            .openTangemPay()
            .waitForScreen()
            .openMoreActionsMenu()
            .verifyCurrentPlanMenuItem()
            .tapCurrentPlanMenuItem()
            .waitForScreen()
            .verifyChangePlanUnavailable()
    }

    func testCardsLimit_OnBasicPlan_OffersPlanUpgrade() {
        setAllureId(10385)

        launchWithPlan(state: "BasicThreeCards", transitions: "FromBasic", offers: "NoOffers")
            .openTangemPay()
            .waitForScreen()
            .tapAddCardExpectingCardsLimit()
            .waitForSheet()
            .verifyContent(title: Localization.tangempayMaximumCardsIssuedForPlanTitle, description: Localization.tangempayMaximumCardsIssuedForPlanDescription)
            .verifyCancelButton()
    }

    func testCardsLimit_OnPlusPlan_ShowsMaximumCardsIssued() {
        setAllureId(10386)

        launchWithPlan(state: "PlusFiveCards", transitions: "NoTransitions", offers: "NoOffers")
            .openTangemPay()
            .waitForScreen()
            .tapAddCardExpectingMaximumCards()
            .waitForSheet()
            .verifyContent(title: Localization.tangempayMaximumCardsIssuedTitle, description: Localization.tangempayMaximumCardsIssuedDescription)
    }

    func testCardsLimit_OnBasicPlan_UpgradeOpensPlanSelection() {
        setAllureId(10387)

        launchWithPlan(state: "BasicThreeCards", transitions: "FromBasic", offers: "NoOffers")
            .openTangemPay()
            .waitForScreen()
            .tapAddCardExpectingCardsLimit()
            .waitForSheet()
            .tapUpgradePlan()
            .waitForScreen()
            .verifyPlanName(Constants.Plan.plus)
    }

    @discardableResult
    private func launchWithPlan(
        state: String,
        transitions: String,
        balance: String = "InitialBalance",
        orders: String = "Empty",
        order: String = "Started",
        offers: String? = nil
    ) -> MainScreen {
        var scenarios = [
            ScenarioConfig(name: Constants.Scenario.plan, initialState: state),
            ScenarioConfig(name: Constants.Scenario.transitions, initialState: transitions),
            ScenarioConfig(name: Constants.Scenario.orders, initialState: orders),
            ScenarioConfig(name: Constants.Scenario.order, initialState: order),
            ScenarioConfig(name: Constants.Scenario.basicOrder, initialState: "Completed"),
            ScenarioConfig(name: Constants.Scenario.cardIssueOrders, initialState: "Empty"),
            ScenarioConfig(name: Constants.Scenario.balance, initialState: balance),
            ScenarioConfig(name: Constants.Scenario.history, initialState: "InitialEmpty"),
        ]

        if let offers {
            scenarios.append(ScenarioConfig(name: Constants.Scenario.offers, initialState: offers))
        }

        return launchAndImportHotWallet(scenarios: scenarios)
    }

    @discardableResult
    private func launchForOnboarding(balance: String = "InitialBalance") -> MainScreen {
        launchWithPlan(state: "PlanSelectNeeded", transitions: "Onboarding", balance: balance)
    }

    /// Staged before the action, because the app reloads customer info as soon as the request returns.
    private func stagePlanState(_ state: String) {
        wireMockClient.setScenarioStateSync(Constants.Scenario.plan, state: state)
    }

    /// Staged before the action, for the same reason as stagePlanState.
    private func awaitPlanFeePayment(orders: String = "AwaitingDeposit") {
        wireMockClient.setScenarioStateSync(Constants.Scenario.plan, state: "Basic")
        wireMockClient.setScenarioStateSync(Constants.Scenario.orders, state: orders)
        wireMockClient.setScenarioStateSync(Constants.Scenario.order, state: "AwaitingDeposit")
    }

    private func stagePlusOrderIssuing() {
        wireMockClient.setScenarioStateSync(Constants.Scenario.order, state: "Started")
        wireMockClient.setScenarioStateSync(Constants.Scenario.orders, state: "PlusProcessing")
    }

    private func completePlusOrderWithPlanFee() {
        wireMockClient.setScenarioStateSync(Constants.Scenario.history, state: "AfterPlanFee")
        completePlanOrder(planState: "Plus")
    }

    private func stageBasicOrderPolling() {
        wireMockClient.setScenarioStateSync(Constants.Scenario.basicOrder, state: "Processing")
    }

    private func stageBasicOrderIssuing() {
        stageBasicOrderPolling()
        wireMockClient.setScenarioStateSync(Constants.Scenario.orders, state: "BasicProcessing")
    }

    private func completeBasicOrderIssuing() {
        wireMockClient.setScenarioStateSync(Constants.Scenario.basicOrder, state: "Completed")
        wireMockClient.setScenarioStateSync(Constants.Scenario.orders, state: "Empty")
    }

    /// Staged before the action, for the same reason as stagePlanState.
    private func completePlanOrder(planState: String) {
        wireMockClient.setScenarioStateSync(Constants.Scenario.plan, state: planState)
        wireMockClient.setScenarioStateSync(Constants.Scenario.order, state: "Completed")
        wireMockClient.setScenarioStateSync(Constants.Scenario.orders, state: "Empty")
    }

    /// Called after the tap: the cancel stub flips the polled order, and the list drains within a poll interval.
    private func drainPlanOrders() {
        wireMockClient.setScenarioStateSync(Constants.Scenario.orders, state: "Empty")
    }

    private func placeOrderRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.placeOrder)
    }

    private func cancelOrderRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.cancelOrder)
    }

    private func pendingTransitionRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.pendingTransition)
    }

    private func cancelPendingTransitionRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.cancelPendingTransition)
    }

    private func assertOrdersPlaced(since previousCount: Int) {
        assertRequestSent(placeOrderRequestCount, since: previousCount, named: "plan order")
    }

    /// The tap only starts the request, so the counter is polled rather than read once.
    private func assertRequestSent(_ count: () -> Int, since previousCount: Int, named name: String) {
        XCTContext.runActivity(named: "Verify the \(name) request was sent once") { _ in
            let deadline = Date().addingTimeInterval(.conditional)
            var delta = count() - previousCount
            while delta < 1, Date() < deadline {
                delta = count() - previousCount
            }
            XCTAssertEqual(delta, 1, "The \(name) request should be sent once, but the delta was \(delta)")
        }
    }
}

private extension TangemPayTariffPlansUITests {
    enum Constants {
        enum Scenario {
            static let plan = "tangem_pay_tariff_plan"
            static let transitions = "tangem_pay_tariff_plan_transitions"
            static let orders = "tangem_pay_tariff_plan_orders"
            static let order = "tangem_pay_tariff_plan_order"
            static let basicOrder = "tangem_pay_tariff_plan_basic_order"
            static let offers = "tangem_pay_tariff_plan_offers"
            static let cardIssueOrders = "tangem_pay_card_issue_orders"
            static let balance = "tangem_pay_balance_update"
            static let history = "tangem_pay_transaction_history"
        }

        enum Endpoint {
            static let placeOrder = "/bff-v2/v1/order"
            static let cancelOrder = "/bff-v2/v1/order/mock-tariff-plan-order-001/cancel"
            static let pendingTransition = "/bff-v2/v1/customer/tariff-plan/pending-transition"
            static let cancelPendingTransition = "/bff-v2/v1/customer/tariff-plan/pending-transition/cancel"
        }

        enum Plan {
            static let basic = "Basic"
            static let plus = "Plus"
            static let plusProgram = "Visa Signature"
            static let plusFee = "$29.99"
        }

        enum Card {
            static let id = "mock-card-id"
        }

        enum Transaction {
            static let planFee = "Plus monthly plan fee"
        }
    }
}
