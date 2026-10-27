//
//  TangemPayBankOfframpTransferUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayBankOfframpTransferUITests: TangemPayBankOfframpUITestCase {
    func testAmount_ValidatedAgainstLimitsBalanceAndRailFee() {
        setAllureId(12185)

        let rangeError = Localization.tangempayWithdrawBankAmountErrorRange(Constants.Amount.minimum, Constants.Amount.maximum)
        let notEnoughFunds = Localization.tangempayWithdrawBankAmountNotEnoughFunds

        openPaymentAccount(balance: .bankOfframp)
            .tapWithdrawOpeningHub()
            .tapToBusinessAccount()
            .verifySourceToken(symbol: Constants.usdcSymbol, network: TangemPayNetwork.polygon.displayName)
            .verifyRail(.ach)
            .tapMax()
            .verifyAmount(contains: Constants.Amount.maxWithAch)
            .verifyNoAmountError()
            .verifyContinueEnabled(true)
            .selectRail(.wire)
            .verifyAmountError(notEnoughFunds)
            .verifyContinueEnabled(false)
            .tapMax()
            .verifyAmount(contains: Constants.Amount.maxWithWire)
            .verifyNoAmountError()
            .verifyContinueEnabled(true)
            .replaceAmount(Constants.Amount.belowMinimum)
            .verifyAmountError(rangeError)
            .verifyContinueEnabled(false)
            .replaceAmount(Constants.Amount.aboveMaximum)
            .verifyAmountError(rangeError)
            .verifyContinueEnabled(false)
            .replaceAmount(Constants.Amount.aboveBalance)
            .verifyAmountError(notEnoughFunds)
            .verifyContinueEnabled(false)
            .replaceAmount(Constants.Amount.valid)
            .verifyNoAmountError()
            .verifyContinueEnabled(true)
    }

    func testRails_FromOfframpOptionsOfferedForSelection() {
        setAllureId(12186)

        let paymentAccount = openPaymentAccount(balance: .bankOfframp)
        let optionsRequestsBefore = requestCount(.offrampOptions)

        let hub = paymentAccount.tapWithdrawOpeningHub()
        verifyRequestedAgain(.offrampOptions, since: optionsRequestsBefore, "Opening the Withdraw hub should request the bank off-ramp options")

        hub.tapToPersonalAccount()
            .verifyRail(.ach)
            .tapRail()
            .verifyOptionCount(2)
            .verifyOption(.ach, isSelected: true)
            .verifyOption(.wire, isSelected: false)
            .select(.wire)
            .verifyRail(.wire)
    }

    func testTransfer_ToOwnPersonalCheckingAccount() {
        setAllureId(12187)

        let confirm = openPaymentAccount(balance: .bankOfframp)
            .tapWithdrawOpeningHub()
            .tapToPersonalAccount()
            .verifyRail(.ach)
            .enterAmount(Constants.Amount.transfer)
            .tapContinueToTransferType()
            .verifyTransferTypeNothingSelected()
            .selectTransferType(.ownAccount)
            .selectAccountType(.checking)
            .fillRecipientDetails(.michael)
            .fillBankDetails(.bankOfAmerica)

        send(from: confirm, expecting: Constants.Order.ownPersonalChecking)
    }

    func testTransfer_ToThirdPartyPersonalSavingsAccount() {
        setAllureId(12188)

        let confirm = openPaymentAccount(balance: .bankOfframp)
            .tapWithdrawOpeningHub()
            .tapToPersonalAccount()
            .selectRail(.wire)
            .enterAmount(Constants.Amount.transfer)
            .tapContinueToTransferType()
            .verifyTransferTypeNothingSelected()
            .selectTransferType(.thirdPartyAccount)
            .selectAccountType(.saving)
            .fillRecipientDetails(.emily)
            .fillBankDetails(.jpMorganChase)

        send(from: confirm, expecting: Constants.Order.thirdPartyPersonalSavings)
    }

    func testTransfer_ToBusinessSavingsAccount() {
        setAllureId(12189)

        let confirm = openPaymentAccount(balance: .bankOfframp)
            .tapWithdrawOpeningHub()
            .tapToBusinessAccount()
            .verifyRail(.ach)
            .enterAmount(Constants.Amount.transfer)
            .tapContinueToAccountType()
            .selectAccountType(.saving)
            .fillRecipientDetails(.dunderMifflin)
            .fillBankDetails(.wellsFargo)

        send(from: confirm, expecting: Constants.Order.businessSavings)
    }

    func testTransfer_ToBusinessCheckingAccount() {
        setAllureId(12190)

        let confirm = openPaymentAccount(balance: .bankOfframp)
            .tapWithdrawOpeningHub()
            .tapToBusinessAccount()
            .selectRail(.wire)
            .enterAmount(Constants.Amount.transfer)
            .tapContinueToAccountType()
            .selectAccountType(.checking)
            .fillRecipientDetails(.dunderMifflin)
            .fillBankDetails(.wellsFargo)

        send(from: confirm, expecting: Constants.Order.businessChecking)
    }

    func testOrderCreationError_ShowsErrorScreenWithRetry() {
        setAllureId(12191)

        let confirm = openPaymentAccount(balance: .bankOfframp, extraScenarios: [Constants.orderScenario(Constants.State.orderError)])
            .tapWithdrawOpeningHub()
            .tapToPersonalAccount()
            .enterAmount(Constants.Amount.transfer)
            .tapContinueToTransferType()
            .selectTransferType(.ownAccount)
            .selectAccountType(.saving)
            .fillRecipientDetails(.emily)
            .fillBankDetails(.jpMorganChase)

        let ordersBefore = requestCount(.order, method: Constants.post)
        let errorScreen = confirm
            .tapSendExpectingError()
            .verifyRetryableError()
        verifyRequestedAgain(.order, method: Constants.post, since: ordersBefore, "Send should place the bank off-ramp order")

        let ordersBeforeRetry = requestCount(.order, method: Constants.post)
        errorScreen.tapRetry()
        verifyRequestedAgain(.order, method: Constants.post, since: ordersBeforeRetry, "Retry should place the bank off-ramp order again")

        errorScreen
            .waitForScreen()
            .verifyRetryableError()
            .tapClose()
    }

    func testSendingScreen_ShowsAmountDateAndRecipient() {
        setAllureId(12193)

        let recipient = TangemPayBankTransferWizardScreen.RecipientDetails.michael
        let bank = TangemPayBankTransferWizardScreen.BankDetails.bankOfAmerica

        let confirm = openPaymentAccount(balance: .bankOfframp)
            .tapWithdrawOpeningHub()
            .tapToPersonalAccount()
            .enterAmount(Constants.Amount.transfer)
            .tapContinueToTransferType()
            .selectTransferType(.ownAccount)
            .selectAccountType(.saving)
            .fillRecipientDetails(recipient)
            .fillBankDetails(bank)

        confirm
            .tapSend()
            .waitForScreen(amount: Constants.Amount.sent)
            .verifyDate(Constants.orderCreatedAt)
            .verifyDetail(title: Localization.sendRecipient, value: recipient.name.fullName)
            .verifyDetail(title: Localization.tangempayWithdrawBankFieldBankName, value: bank.name)
            .verifyDetail(title: Localization.tangempayWithdrawBankFieldAccountNumber, value: recipient.accountNumber)
            .tapClose()
    }

    func testRecentRecipients_UpdatedAfterTransfer() {
        setAllureId(12195)

        openPaymentAccount(balance: .bankOfframp, bankAccounts: .twoAccounts)
            .tapWithdrawOpeningHub()
            .verifyRecentRecipient(.john)
            .verifyRecentRecipientNotDisplayed(.jane)
            .tapToPersonalAccount()
            .enterAmount(Constants.Amount.transfer)
            .tapContinueToTransferType()
            .selectTransferType(.thirdPartyAccount)
            .selectAccountType(.checking)
            .fillRecipientDetails(.jane)
            .fillBankDetails(.chase)
            .tapSend()
            .waitForScreen(amount: Constants.Amount.sent)
            .tapClose()

        switchBankAccounts(to: .twoAccountsAfterTransfer)

        TangemPayMainScreen(app)
            .tapWithdrawOpeningHub()
            .verifyRecentRecipient(.jane)
            .verifyRecentRecipient(.john)
    }

    func testConfirmation_EditsAmountSourceAndRail() {
        setAllureId(12196)

        let michael = TangemPayBankTransferWizardScreen.RecipientDetails.michael
        let bankOfAmerica = TangemPayBankTransferWizardScreen.BankDetails.bankOfAmerica

        let confirm = openOwnCheckingConfirmation(recipient: michael, bank: bankOfAmerica)
            .verifyAmountCard(amount: Constants.Amount.sent, balance: Constants.Balance.polygon)
            .verifyRail(.ach)
            .verifyRailEditable(true)
            .verifyRecipientDetails([michael.accountNumber, michael.city, bankOfAmerica.name])
            .tapAmountCard()
            .replaceAmount(Constants.Amount.edited)
            .selectSourceToken(symbol: Constants.usdcSymbol, network: .arbitrum)
            .selectRail(.wire)
            .tapContinueToConfirmation()
            .verifyAmountCard(amount: Constants.Amount.editedSent, balance: Constants.Balance.arbitrum)
            .verifyRail(.wire)
            .verifyRecipientDetails([michael.accountNumber, bankOfAmerica.name])

        let ordersBefore = bankOfframpOrderCount(matching: Constants.Order.editedAmountSourceAndRail)
        confirm.tapSend()
        verifyBankOfframpOrderSent(Constants.Order.editedAmountSourceAndRail, since: ordersBefore)
    }

    func testConfirmation_EditsRecipientAndBankDetails() {
        setAllureId(13175)

        let michael = TangemPayBankTransferWizardScreen.RecipientDetails.michael
        let emily = TangemPayBankTransferWizardScreen.RecipientDetails.emily
        let bankOfAmerica = TangemPayBankTransferWizardScreen.BankDetails.bankOfAmerica
        let jpMorganChase = TangemPayBankTransferWizardScreen.BankDetails.jpMorganChase

        let confirm = openOwnCheckingConfirmation(recipient: michael, bank: bankOfAmerica)
            .verifyRecipientDetails([michael.accountNumber, michael.city, bankOfAmerica.name])
            .tapSection(containing: michael.accountNumber)
            .verifyFieldValue(.accountNumber, michael.accountNumber)
            .replaceText(in: .accountNumber, with: emily.accountNumber)
            .tapContinueToConfirmation()
            .verifyRecipientDetails([emily.accountNumber])
            .tapSection(containing: bankOfAmerica.name)
            .verifyFieldValue(.bankName, bankOfAmerica.name)
            .replaceText(in: .bankName, with: jpMorganChase.name)
            .tapContinueToConfirmation()
            .verifyRecipientDetails([jpMorganChase.name])

        let ordersBefore = bankOfframpOrderCount(matching: Constants.Order.editedRecipientAndBank)
        confirm.tapSend()
        verifyBankOfframpOrderSent(Constants.Order.editedRecipientAndBank, since: ordersBefore)
    }

    func testRecentRecipient_DetailsNotEditable() {
        setAllureId(12197)

        let confirm = openPaymentAccount(balance: .bankOfframp, bankAccounts: .twoAccounts)
            .tapWithdrawOpeningHub()
            .tapRecentRecipient(.john)
            .verifyTitle(TangemPayBankRecipient.john.fullName)
            .verifyRail(.ach)
            .verifyRailNotSelectable()
            .enterAmount(Constants.Amount.transfer)
            .selectSourceToken(symbol: Constants.usdcSymbol, network: .polygon)
            .tapContinueToConfirmation()
            .verifyAmountCard(amount: Constants.Amount.sent, balance: Constants.Balance.polygon)
            .verifyRailEditable(false)
            .verifySectionsNotEditable()
            .verifyRecipientDetails(Constants.johnSavedDetails)
            .tapAmountCard()
            .verifyRailNotSelectable()
            .replaceAmount(Constants.Amount.edited)
            .selectSourceToken(symbol: Constants.usdcSymbol, network: .arbitrum)
            .tapContinueToConfirmation()
            .verifyAmountCard(amount: Constants.Amount.editedSent, balance: Constants.Balance.arbitrum)
            .verifySectionsNotEditable()

        let ordersBefore = bankOfframpOrderCount(matching: Constants.Order.editedSavedJohn)
        confirm.tapSend()
        verifyBankOfframpOrderSent(Constants.Order.editedSavedJohn, since: ordersBefore)
    }

    func testOrder_PolledUntilAwaitingSignature() {
        setAllureId(12198)

        let confirm = openPaymentAccount(balance: .bankOfframp, extraScenarios: [Constants.orderScenario(Constants.State.orderPolling)])
            .tapWithdrawOpeningHub()
            .tapToBusinessAccount()
            .enterAmount(Constants.Amount.transfer)
            .tapContinueToAccountType()
            .selectAccountType(.saving)
            .fillRecipientDetails(.dunderMifflin)
            .fillBankDetails(.wellsFargo)

        let ordersBefore = requestCount(.order, method: Constants.post)
        let pollsBefore = requestCount(.orderStatus)
        let signaturesBefore = requestCount(.orderSignature, method: Constants.post)

        let success = confirm
            .tapSend()
            .waitForScreen(amount: Constants.Amount.sent)

        verifyRequestedAgain(.order, method: Constants.post, since: ordersBefore, "Send should place the bank off-ramp order")
        verifyRequestCount(
            .orderStatus,
            exceeds: pollsBefore + 1,
            "The order should be polled again after the first status still lacks the signature step"
        )
        XCTContext.runActivity(named: "Verify the signature was submitted once") { _ in
            XCTAssertEqual(
                requestCount(.orderSignature, method: Constants.post) - signaturesBefore,
                1,
                "The signature should be submitted exactly once, after the order reached AWAITING_SIGNATURE"
            )
        }

        success.tapClose()
    }

    func testBankAccountDetails_NumbersAndPostalCodesValidated() {
        setAllureId(12200)

        let invalidFormat = Localization.tangempayWithdrawBankFieldErrorInvalidFormat
        let wizard = openPersonalRecipientForm()

        verify(wizard, rejects: Constants.Invalid.accountNumbers, in: .accountNumber, with: invalidFormat)
        verify(wizard, rejects: Constants.Invalid.routingNumbers, in: .routingNumber, with: Localization.tangempayWithdrawBankFieldErrorRoutingNumber)

        wizard.selectCountry(Constants.Country.germany)
        verify(wizard, rejects: [Constants.Invalid.internationalPostalCode], in: .postalCode, with: invalidFormat)
        verify(wizard, accepts: [Constants.Valid.internationalPostalCode], in: .postalCode)

        wizard.selectCountry(Constants.Country.unitedStates, region: Constants.Country.california)
        verify(wizard, rejects: [Constants.Invalid.usPostalCode], in: .postalCode, with: invalidFormat)
        verify(wizard, accepts: [Constants.Valid.usPostalCode], in: .postalCode)

        wizard
            .fillRecipientDetails(.michael)
            .waitForBankDetailsForm()
    }

    func testBankAccountDetails_TextFieldsAcceptLatinOnly() {
        setAllureId(12738)

        let latinOnly = Localization.tangempayOrderDataFieldLatinOnly
        let wizard = openPersonalRecipientForm()

        wizard.selectCountry(Constants.Country.germany)
        for (field, invalid, valid) in Constants.latinOnlyFields {
            verify(wizard, rejects: [invalid], in: field, with: latinOnly)
            verify(wizard, accepts: [valid], in: field)
        }

        let businessWizard = wizard
            .close()
            .tapWithdrawOpeningHub()
            .tapToBusinessAccount()
            .enterAmount(Constants.Amount.transfer)
            .tapContinueToAccountType()
            .selectAccountType(.checking)
            .waitForRecipientDetailsForm()
        verify(businessWizard, rejects: [Constants.Invalid.businessName], in: .businessName, with: latinOnly)
        verify(businessWizard, accepts: [Constants.Valid.businessName], in: .businessName)
    }

    private func openOwnCheckingConfirmation(
        recipient: TangemPayBankTransferWizardScreen.RecipientDetails,
        bank: TangemPayBankTransferWizardScreen.BankDetails
    ) -> TangemPayBankTransferConfirmScreen {
        openPaymentAccount(balance: .bankOfframp)
            .tapWithdrawOpeningHub()
            .tapToPersonalAccount()
            .enterAmount(Constants.Amount.transfer)
            .tapContinueToTransferType()
            .selectTransferType(.ownAccount)
            .selectAccountType(.checking)
            .fillRecipientDetails(recipient)
            .fillBankDetails(bank)
    }

    private func openPersonalRecipientForm() -> TangemPayBankTransferWizardScreen {
        openPaymentAccount(balance: .bankOfframp, extraScenarios: [Constants.geoWithGermany])
            .tapWithdrawOpeningHub()
            .tapToPersonalAccount()
            .enterAmount(Constants.Amount.transfer)
            .tapContinueToTransferType()
            .verifyTransferTypeNothingSelected()
            .selectTransferType(.ownAccount)
            .selectAccountType(.checking)
            .waitForRecipientDetailsForm()
    }

    private func send(from confirm: TangemPayBankTransferConfirmScreen, expecting order: TangemPayBankOfframpOrderRequest) {
        let ordersBefore = bankOfframpOrderCount(matching: order)
        let pollsBefore = requestCount(.orderStatus)

        let success = confirm
            .tapSend()
            .waitForScreen(amount: Constants.Amount.sent)

        verifyBankOfframpOrderSent(order, since: ordersBefore)
        verifyRequestedAgain(.orderStatus, since: pollsBefore, "The placed order should be polled for its status")
        success.tapClose()
    }

    private func verify(
        _ wizard: TangemPayBankTransferWizardScreen,
        rejects values: [String],
        in field: TangemPayBankTransferWizardScreen.FormField,
        with message: String
    ) {
        for value in values {
            wizard
                .replaceText(in: field, with: value)
                .verifyFieldError(field, message)
        }
    }

    private func verify(
        _ wizard: TangemPayBankTransferWizardScreen,
        accepts values: [String],
        in field: TangemPayBankTransferWizardScreen.FormField
    ) {
        for value in values {
            wizard
                .replaceText(in: field, with: value)
                .verifyNoFieldError(field)
        }
    }
}

private extension TangemPayBankOfframpTransferUITests {
    enum Constants {
        static let usdcSymbol = "USDC"
        static let post = "POST"

        static let orderCreatedAt: Date = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            return formatter.date(from: "2026-10-09T00:00:00.000+0000") ?? Date(timeIntervalSince1970: 0)
        }()

        static let johnSavedDetails = [TangemPayBankRecipient.john.accountNumber, "021000021", "John", "Doe", "Chase Bank"]

        static let geoWithGermany = ScenarioConfig(name: Scenario.geoCountries, initialState: State.withGermany)

        static let latinOnlyFields: [(TangemPayBankTransferWizardScreen.FormField, String, String)] = [
            (.region, "Βαυαρία", "Württemberg"),
            (.firstName, "Γιάννης", "José"),
            (.lastName, "Παπαδόπουλος", "Müller"),
            (.city, "Αθήνα", "São Paulo"),
            (.line1, "Οδός 1", "Straße 1"),
            (.line2, "Διαμέρισμα 5", "Côte 5"),
        ]

        static func orderScenario(_ state: String) -> ScenarioConfig {
            ScenarioConfig(name: Scenario.order, initialState: state)
        }

        enum Scenario {
            static let order = "tangem_pay_bank_offramp_order"
            static let geoCountries = "tangem_pay_geo_countries"
        }

        enum State {
            static let orderError = "Error"
            static let orderPolling = "Polling"
            static let withGermany = "WithGermany"
        }

        enum Amount {
            static let transfer = "5"
            static let sent = "$5"
            static let edited = "7"
            static let editedSent = "$7"
            static let minimum = "$1"
            static let maximum = "$10,000"
            static let maxWithAch = "98.5"
            static let maxWithWire = "85"
            static let belowMinimum = "0.5"
            static let aboveMaximum = "10001"
            static let aboveBalance = "5000"
            static let valid = "50"
        }

        enum Balance {
            static let polygon = "$100.00"
            static let arbitrum = "$50.00"
        }

        enum Country {
            static let germany = "Germany"
            static let unitedStates = "United States"
            static let california = "California"
        }

        enum Invalid {
            static let accountNumbers = ["123", "123456789012345678", "12345-678"]
            static let routingNumbers = ["02600959", "0260095931", "02600959A"]
            static let businessName = "Εταιρεία Α"
            static let usPostalCode = "ABCDE"
            static let internationalPostalCode = "10115#"
        }

        enum Valid {
            static let businessName = "Société Générale"
            static let internationalPostalCode = "10115AB"
            static let usPostalCode = "32501"
        }

        enum Order {
            static let ownPersonalChecking = TangemPayBankOfframpOrderRequest(
                amountInCents: 500,
                chainId: TangemPayNetwork.polygon.chainId,
                details: .init(
                    rail: Rail.ach,
                    bankAccountType: AccountType.checking,
                    beneficiaryType: Beneficiary.individual,
                    isThirdParty: false,
                    accountNumber: "9876543210",
                    bankName: "Bank of America"
                )
            )

            static let thirdPartyPersonalSavings = TangemPayBankOfframpOrderRequest(
                amountInCents: 500,
                chainId: TangemPayNetwork.polygon.chainId,
                details: .init(
                    rail: Rail.wire,
                    bankAccountType: AccountType.savings,
                    beneficiaryType: Beneficiary.individual,
                    isThirdParty: true,
                    accountNumber: "8765432109",
                    bankName: "JPMorgan Chase"
                )
            )

            static let businessSavings = TangemPayBankOfframpOrderRequest(
                amountInCents: 500,
                chainId: TangemPayNetwork.polygon.chainId,
                details: .init(
                    rail: Rail.ach,
                    bankAccountType: AccountType.savings,
                    beneficiaryType: Beneficiary.business,
                    isThirdParty: true,
                    accountNumber: "7654321098",
                    bankName: "Wells Fargo Bank"
                )
            )

            static let businessChecking = TangemPayBankOfframpOrderRequest(
                amountInCents: 500,
                chainId: TangemPayNetwork.polygon.chainId,
                details: .init(
                    rail: Rail.wire,
                    bankAccountType: AccountType.checking,
                    beneficiaryType: Beneficiary.business,
                    isThirdParty: true,
                    accountNumber: "7654321098",
                    bankName: "Wells Fargo Bank"
                )
            )

            static let editedAmountSourceAndRail = TangemPayBankOfframpOrderRequest(
                amountInCents: 700,
                chainId: TangemPayNetwork.arbitrum.chainId,
                details: .init(
                    rail: Rail.wire,
                    bankAccountType: AccountType.checking,
                    beneficiaryType: Beneficiary.individual,
                    isThirdParty: false,
                    accountNumber: "9876543210",
                    bankName: "Bank of America"
                )
            )

            static let editedRecipientAndBank = TangemPayBankOfframpOrderRequest(
                amountInCents: 500,
                chainId: TangemPayNetwork.polygon.chainId,
                details: .init(
                    rail: Rail.ach,
                    bankAccountType: AccountType.checking,
                    beneficiaryType: Beneficiary.individual,
                    isThirdParty: false,
                    accountNumber: "8765432109",
                    bankName: "JPMorgan Chase"
                )
            )

            static let editedSavedJohn = TangemPayBankOfframpOrderRequest(
                amountInCents: 700,
                chainId: TangemPayNetwork.arbitrum.chainId,
                bankAccountId: "mock-bank-account-john"
            )

            enum Rail {
                static let ach = "ACH"
                static let wire = "WIRE"
            }

            enum AccountType {
                static let checking = "CHECKING"
                static let savings = "SAVINGS"
            }

            enum Beneficiary {
                static let individual = "INDIVIDUAL"
                static let business = "BUSINESS"
            }
        }
    }
}
