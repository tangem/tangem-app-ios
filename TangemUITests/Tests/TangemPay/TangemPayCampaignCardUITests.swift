//
//  TangemPayCampaignCardUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayCampaignCardUITests: BaseTestCase {
    private let safariHelper = SafariHelper()

    func testCampaignCard_IsOrdered_WhenLinkIsOpenedWithoutWallet() {
        setAllureId(11647)

        launchApp(
            tangemApiType: .mock,
            visaApiType: .mock,
            clearStorage: true,
            scenarios: [ScenarioConfig(name: Constants.Scenario.eligibility, initialState: Constants.State.notPaeraCustomer)]
                + newCustomerScenarios
        )

        openCampaignLink()

        let landing = TangemPayCampaignLandingScreen(app)
            .waitForScreen()
            .verifyContent()
            .verifyCloseButton(exists: false)
            .verifyLegalCaption(exists: true)

        verifyCampaignLinkValidated()

        let mainScreen = orderCampaignCard(from: landing)
            .skipPushNotificationsSetup()

        verifyCampaignOrderPlaced()
        verifyCardIssuingAfterKycApproval(on: mainScreen)
            .openTangemPay()
            .verifyIssuingCardBanner()
    }

    func testCampaignCard_IsOrdered_WhenWalletHasNoTangemPay() {
        setAllureId(11648)

        let mainScreen = launchAndImportHotWallet(
            eligibilityState: Constants.State.notPaeraCustomer,
            scenarios: newCustomerScenarios
        )

        openCampaignLink()

        let landing = TangemPayCampaignLandingScreen(app)
            .waitForScreen()
            .verifyContent()
            .verifyCloseButton(exists: true)
            .verifyLegalCaption(exists: false)

        verifyCampaignLinkValidated()
        orderCampaignCard(from: landing)
        verifyCampaignOrderPlaced()

        let paymentAccount = verifyCardIssuingAfterKycApproval(on: mainScreen)
            .openDetails()
            .verifyWalletsCount(1)
            .goBackToMain()
            .openTangemPay()
            .verifyIssuingCardBanner()

        wireMockClient.setScenarioStateSync(Constants.Scenario.campaignCard, state: Constants.State.cardIssued)
        wireMockClient.setScenarioStateSync(Constants.Scenario.issueOrder, state: Constants.State.completed)
        wireMockClient.setScenarioStateSync(Constants.Scenario.issueOrders, state: Constants.State.empty)

        paymentAccount
            .waitForIssuingCardBannerHidden()
            .verifyCardDisplayed(cardId: Constants.Card.campaignCardId)
    }

    func testAdditionalCampaignCard_IsIssued_WhenPaymentAccountIsActive() {
        setAllureId(11649)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: Constants.Scenario.issueOrder, initialState: Constants.State.started),
            ScenarioConfig(name: Constants.Scenario.issueOrders, initialState: Constants.State.empty),
        ])

        openCampaignLink()

        let paymentAccount = TangemPayCampaignIssueCardScreen(app)
            .waitForScreen()
            .verifyContent(feeValue: Constants.issueFee)
            .tapIssue()
            .verifyIssuingCardBanner()

        verifyCampaignOrderPlaced()

        wireMockClient.setScenarioStateSync(Constants.Scenario.cardIssue, state: Constants.State.twoCards)
        wireMockClient.setScenarioStateSync(Constants.Scenario.issueOrder, state: Constants.State.completed)
        wireMockClient.setScenarioStateSync(Constants.Scenario.issueOrders, state: Constants.State.empty)

        paymentAccount
            .waitForIssuingCardBannerHidden()
            .verifyCardDisplayed(cardId: Constants.Card.issuedCardId)
            .tapCard(cardId: Constants.Card.issuedCardId)
            .waitForScreen()
    }

    private var newCustomerScenarios: [ScenarioConfig] {
        [
            ScenarioConfig(name: Constants.Scenario.kycStatus, initialState: Constants.State.kycInProgress),
            ScenarioConfig(name: Constants.Scenario.issueOrders, initialState: Constants.State.empty),
        ]
    }

    private func openCampaignLink() {
        XCTContext.runActivity(named: "Open the campaign link \(Constants.Link.campaign) from Safari") { _ in
            wireMockClient.resetRequestJournalSync()
            safariHelper.safari.launch()
            safariHelper.openDeeplink(Constants.Link.campaign)
            safariHelper.tapOpenButton()
        }
    }

    @discardableResult
    private func orderCampaignCard(from landing: TangemPayCampaignLandingScreen) -> MainScreen {
        wireMockClient.setScenarioStateSync(Constants.Scenario.eligibility, state: Constants.State.paeraCustomer)
        return landing.tapGetCard()
    }

    private func verifyCardIssuingAfterKycApproval(on mainScreen: MainScreen) -> MainScreen {
        mainScreen.verifyTangemPayTileSubtitle(contains: Localization.tangempayKycInProgress)

        wireMockClient.setScenarioStateSync(Constants.Scenario.campaignCard, state: Constants.State.kycApprovedIssuing)
        pullToRefresh()

        return mainScreen.verifyTangemPayTileSubtitle(contains: Localization.tangempayIssuingYourCard)
    }

    private func verifyCampaignLinkValidated() {
        XCTContext.runActivity(named: "Verify the campaign link was validated") { _ in
            let links = wireMockClient
                .findRequestBodiesSync(method: "POST", urlPath: Constants.Endpoint.validate)
                .map { body -> String? in jsonObject(from: body)?[Constants.Key.link] as? String }
            XCTAssertEqual(links, [Constants.Link.validated], "The campaign link should be validated once")
        }
    }

    private func verifyCampaignOrderPlaced() {
        XCTContext.runActivity(named: "Verify the campaign card order was placed with the campaign key") { _ in
            let deeplinkValues = wireMockClient
                .findRequestBodiesSync(method: "POST", urlPath: Constants.Endpoint.order)
                .map { body -> String? in
                    let data = jsonObject(from: body)?[Constants.Key.data] as? [String: Any]
                    return data?[Constants.Key.deeplinkValue] as? String
                }
            XCTAssertEqual(deeplinkValues, [Constants.campaignKey], "One card order should be placed with the campaign key")
        }
    }

    private func jsonObject(from body: String) -> [String: Any]? {
        (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [String: Any]
    }
}

private extension TangemPayCampaignCardUITests {
    enum Constants {
        static let campaignKey = "tpay_for_unical1"
        static let issueFee = "$1"

        enum Link {
            static let campaign = "tangem://marketing?deep_link_value=tpay_for_unical1"
            static let validated = "tangem://marketing/tpay_for_unical1"
        }

        enum Scenario {
            static let eligibility = "tangem_pay_eligibility"
            static let kycStatus = "tangem_pay_kyc_status"
            static let campaignCard = "tangem_pay_campaign_card"
            static let cardIssue = "tangem_pay_card_issue"
            static let issueOrder = "tangem_pay_card_issue_order"
            static let issueOrders = "tangem_pay_card_issue_orders"
        }

        enum State {
            static let notPaeraCustomer = "Started"
            static let paeraCustomer = "PaeraCustomer"
            static let kycInProgress = "InProgress"
            static let kycApprovedIssuing = "KycApprovedIssuing"
            static let cardIssued = "CardIssued"
            static let started = "Started"
            static let empty = "Empty"
            static let completed = "Completed"
            static let twoCards = "TwoCards"
        }

        enum Endpoint {
            static let validate = "/bff-v2/v1/deeplink/validate"
            static let order = "/bff-v2/v1/order"
        }

        enum Key {
            static let link = "link"
            static let data = "data"
            static let deeplinkValue = "deeplink_value"
        }

        enum Card {
            static let campaignCardId = "mock-card-id"
            static let issuedCardId = "mock-card-id-2"
        }
    }
}
