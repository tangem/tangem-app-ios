//
//  BaseTestCase.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

class BaseTestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
    }

    override func tearDown() {
        app.launchArguments.removeAll()
        app.launchEnvironment.removeAll()
        app.terminate()

        super.tearDown()

        // Attach exported log file if it exists
        do {
            let documents = try XCTUnwrap(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
            let logFile = documents.appendingPathComponent("api_logs.txt")

            if let logs = try? String(contentsOf: logFile) {
                let attachment = XCTAttachment(string: logs)
                attachment.name = "API Logs"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        } catch {
            XCTFail("Couldn't attach log file")
        }
    }

    func launchApp(resetToS: Bool = false, additionalArguments: [String] = []) {
        var arguments = ["--uitesting", "--alpha"]

        if resetToS {
            arguments.append(contentsOf: ["-tangem_tap_terms_of_service_accepted", "NULL"])
        }

        arguments.append(contentsOf: additionalArguments)

        app.launchArguments = arguments
        app.launchEnvironment = ["UITEST": "1"]
        app.launch()
    }

    func launchApp(
        tangemApiType: TangemAPI? = nil,
        resetToS: Bool = false,
        additionalArguments: [String] = []
    ) {
        var arguments = ["--uitesting", "--alpha"]

        // Check if tangem_api_type is already passed via fastlane/xcargs
        let hasTangemApiTypeFromFastlane = ProcessInfo.processInfo.arguments.contains("-tangem_api_type")

        // Only add tangem_api_type if it's not already provided by fastlane
        if !hasTangemApiTypeFromFastlane, let tangemApiType {
            arguments.append(contentsOf: ["-tangem_api_type", tangemApiType.rawValue])
        }

        if resetToS {
            arguments.append(contentsOf: ["-tangem_tap_terms_of_service_accepted", "NULL"])
        }

        arguments.append(contentsOf: additionalArguments)

        app.launchArguments = arguments
        app.launchEnvironment = ["UITEST": "1"]
        app.launch()
    }
}
