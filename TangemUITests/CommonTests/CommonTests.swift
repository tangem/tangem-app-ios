//
//    CommonTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

class CommonTests: XCTestCase {
    var app = XCUIApplication()

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

    func launchApp() {
        app.launch()
    }
}
