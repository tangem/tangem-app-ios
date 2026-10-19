//
//  BaseTestCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

class BaseTestCase: XCTestCase {
    let app = XCUIApplication()

    // MARK: - WireMock Support

    lazy var wireMockClient = WireMockClient()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        resetAllWireMockScenarios()
    }

    override func tearDown() {
        app.launchArguments.removeAll()
        app.launchEnvironment.removeAll()
        app.terminate()

        super.tearDown()
    }

    func launchApp(
        tangemApiType: TangemAPI? = nil,
        expressApiType: ExpressAPI? = nil,
        stakingApiType: StakingAPI? = nil,
        visaApiType: VisaAPI? = nil,
        yieldApiType: YieldAPI? = nil,
        skipToS: Bool = true,
        clearStorage: Bool = false,
        keepWallets: Bool = false,
        featureToggles: [String: Bool] = [:],
        scenarios: [ScenarioConfig] = [],
        mockCardBatchIdOverride: String? = nil,
        mockCardFirmwareOverride: String? = nil,
        extraLaunchArguments: [String] = [],
        extraLaunchEnvironment: [String: String] = [:]
    ) {
        var arguments: [String] = []

        arguments.append(contentsOf: [
            "-tangem_api_type", tangemApiType?.rawValue ?? TangemAPI.prod.rawValue,
        ])

        arguments.append(contentsOf: [
            "-api_express", expressApiType?.rawValue ?? ExpressAPI.production.rawValue,
        ])

        arguments.append(contentsOf: [
            "-stake_kit_api_type", stakingApiType?.rawValue ?? StakingAPI.prod.rawValue,
        ])

        arguments.append(contentsOf: [
            "-visa_api_type", visaApiType?.rawValue ?? VisaAPI.prod.rawValue,
        ])

        arguments.append(contentsOf: [
            "-yield_module_api_type", yieldApiType?.rawValue ?? YieldAPI.prod.rawValue,
        ])

        if skipToS {
            arguments.append("-uitest-skip-tos")
        }

        if clearStorage {
            arguments.append("-uitest-clear-storage")
        }

        if keepWallets {
            arguments.append("-uitest-keep-wallets")
        }

        // Per-test overrides first, then run-wide CI/Allure ones (UITEST_FEATURE_TOGGLES) win.
        // Keys are Feature names (e.g. TWI-1259_tron_gasless); the app skips unknown ones.
        let resolvedFeatureToggles = featureToggles
            .merging(FeatureToggleUITestsOverridesProvider.runOverrides) { _, runOverride in runOverride }
        for (key, isEnabled) in resolvedFeatureToggles {
            arguments.append("-uitest-feature-\(key)-\(isEnabled ? "on" : "off")")
        }

        arguments.append(contentsOf: extraLaunchArguments)

        // Pin locale/language so currency, number and date assertions don't depend on the simulator region.
        arguments.append(contentsOf: UITestLocale.launchArguments)

        app.launchArguments = arguments

        // Build launch environment with resolved WireMock URL for parallel test support
        // WireMockPortResolver determines the correct port based on simulator UDID
        let wireMockURL = WireMockPortResolver.wireMockBaseURL

        var launchEnvironment = ["UITEST": "1"]
        launchEnvironment["WIREMOCK_BASE_URL"] = wireMockURL
        if let mockCardBatchIdOverride {
            launchEnvironment["UITEST_MOCK_CARD_BATCH_ID"] = mockCardBatchIdOverride
        }
        if let mockCardFirmwareOverride {
            launchEnvironment["UITEST_MOCK_CARD_FIRMWARE"] = mockCardFirmwareOverride
        }
        launchEnvironment.merge(extraLaunchEnvironment) { _, new in new }
        app.launchEnvironment = launchEnvironment

        // Setup WireMock scenarios before launching the app
        setupWireMockScenarios(scenarios)

        app.launch()
    }

    // MARK: - WireMock Scenario Management

    func setupWireMockScenarios(_ scenarios: [ScenarioConfig]) {
        guard !scenarios.isEmpty else { return }

        XCTContext.runActivity(named: "Setup WireMock scenarios") { _ in
            // Set initial states for specified scenarios (setUp resets all scenarios before each test)
            for scenario in scenarios {
                wireMockClient.setScenarioStateSync(scenario.name, state: scenario.initialState)
            }
        }
    }

    private func resetAllWireMockScenarios() {
        XCTContext.runActivity(named: "Reset all WireMock scenarios") { _ in
            wireMockClient.resetAllScenariosSync()
        }
    }

    func pullToRefresh() {
        XCTContext.runActivity(named: "Perform pull to refresh") { _ in
            // Try to find common scrollable elements in order of preference
            let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            let finishCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1))

            startCoordinate.press(forDuration: 0.1, thenDragTo: finishCoordinate)

            // Wait for refresh to complete by waiting for state to change back to idle
            let refreshStateIdle = app.otherElements[MainAccessibilityIdentifiers.refreshStateIdle]
            XCTAssertTrue(refreshStateIdle.waitForExistence(timeout: .conditional), "Refresh state should change to idle when refresh is complete")
        }
    }

    // MARK: - App Lifecycle Management

    func minimizeApp() {
        XCTContext.runActivity(named: "Minimize application") { _ in
            XCUIDevice.shared.press(.home)
        }
    }

    func maximizeApp() {
        XCTContext.runActivity(named: "Maximize application") { _ in
            app.activate()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5.0), "App should be running in foreground")
        }
    }

    // MARK: - Hot Wallet

    @discardableResult
    func importHotWallet(accessCode: String? = nil) -> MainScreen {
        let accessCodeScreen = CreateWalletSelectorScreen(app)
            .importMobileWallet()
            .enterSeedPhrase(TestSeedPhrases.hotWallet)
            .tapImportButton()
            .tapContinue()

        let successScreen = accessCode.map(accessCodeScreen.setAccessCode) ?? accessCodeScreen.skipAccessCode()

        return successScreen.tapFinish()
    }

    @discardableResult
    func launchAndImportHotWallet(
        eligibilityState: String = "PaeraCustomer",
        accessCode: String? = nil,
        expressApiType: ExpressAPI? = nil,
        scenarios: [ScenarioConfig] = [],
        featureToggles: [String: Bool] = [:],
        extraLaunchEnvironment: [String: String] = [:]
    ) -> MainScreen {
        let eligibilityScenario = ScenarioConfig(name: "tangem_pay_eligibility", initialState: eligibilityState)

        launchApp(
            tangemApiType: .mock,
            expressApiType: expressApiType,
            visaApiType: .mock,
            clearStorage: true,
            featureToggles: featureToggles,
            scenarios: [eligibilityScenario] + scenarios,
            extraLaunchEnvironment: extraLaunchEnvironment
        )

        return importHotWallet(accessCode: accessCode)
    }

    /// Signing a withdrawal needs the key the Tangem Pay authorization derives, so the synthetic tokens are skipped.
    @discardableResult
    func launchAndImportHotWalletWithRealPayAuthorization(
        expressApiType: ExpressAPI? = nil,
        scenarios: [ScenarioConfig] = []
    ) -> MainScreen {
        launchAndImportHotWalletRequiringPayRenewal(expressApiType: expressApiType, scenarios: scenarios)
            .renewTangemPaySession()
    }

    @discardableResult
    func launchAndImportHotWalletRequiringPayRenewal(
        expressApiType: ExpressAPI? = nil,
        scenarios: [ScenarioConfig] = []
    ) -> MainScreen {
        launchApp(
            tangemApiType: .mock,
            expressApiType: expressApiType,
            visaApiType: .mock,
            clearStorage: true,
            scenarios: [ScenarioConfig(name: "tangem_pay_eligibility", initialState: "PaeraCustomer")] + scenarios,
            extraLaunchArguments: [Constants.realPayAuthorizationArgument]
        )

        return importHotWallet()
    }

    /// Restarts the app keeping wallets and storage, so caches written before the restart stay readable.
    @discardableResult
    func relaunchKeepingState(
        eligibilityState: String = "PaeraCustomer",
        scenarios: [ScenarioConfig] = []
    ) -> MainScreen {
        XCTContext.runActivity(named: "Restart the app keeping wallets and settings") { _ in
            app.terminate()
            launchApp(
                tangemApiType: .mock,
                visaApiType: .mock,
                keepWallets: true,
                scenarios: [ScenarioConfig(name: "tangem_pay_eligibility", initialState: eligibilityState)] + scenarios
            )
            return MainScreen(app)
        }
    }

    // MARK: - Alert Handling

    func waitAndDismissErrorAlert(
        actionName: String,
        expectedMessage: String = "currently unavailable",
        buttonTitle: String = "OK"
    ) {
        XCTContext.runActivity(named: "Verify and dismiss error alert for \(actionName)") { _ in
            let alert = app.alerts.firstMatch
            XCTAssertTrue(
                alert.waitForExistence(timeout: .robustUIUpdate),
                "Error alert should be displayed after tapping \(actionName) button"
            )

            let alertMessage = alert.staticTexts.element(
                matching: NSPredicate(format: "label CONTAINS %@", expectedMessage)
            ).firstMatch
            XCTAssertTrue(
                alertMessage.exists,
                "Alert should contain message about action being unavailable"
            )

            alert.buttons[buttonTitle].waitAndTap()
        }
    }
}

private extension BaseTestCase {
    enum Constants {
        /// Keeps `TangemPayMocksConfigurator` from injecting synthetic authorization tokens.
        static let realPayAuthorizationArgument = "-uitest-tangempay-real-authorization"
    }
}

extension XCUIApplication {
    func hideKeyboard() {
        toolbars.firstMatch.buttons[CommonUIAccessibilityIdentifiers.hideKeyboardButton].waitAndTap()
    }
}
