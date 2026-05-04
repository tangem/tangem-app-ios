//
//  LogSanitizerTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct LogSanitizerTests {
    @Test(arguments: PipelineTestCase.sampleSteps)
    func shouldExecuteSanitizerPipelineInCorrectOrder(testCase: PipelineTestCase) {
        var receivedPipelineSteps = [PipelineStep]()

        let policy = Self.makeSpyPolicy(
            from: testCase,
            onPreserve: { receivedPipelineSteps.append(.preserve) },
            onRedact: { receivedPipelineSteps.append(.redact) },
            onRestore: { receivedPipelineSteps.append(.restore) }
        )

        _ = LogSanitizer.sanitize("any log", policy: policy)

        #expect(receivedPipelineSteps == testCase.expectedPipelineSteps)
    }

    @Test(arguments: Self.randomIntegerIdentifiers)
    func shouldApplyPreserveRulesInCorrectOrder(orderedRuleIdentifiers: [Int]) {
        var receivedPreserveIdentifiers = [Int]()
        var receivedRestoreIdentifiers = [Int]()

        let preserveRules = orderedRuleIdentifiers.map { id in
            PreserveRule.spy(
                onPreserve: { receivedPreserveIdentifiers.append(id) },
                onRestore: { receivedRestoreIdentifiers.append(id) }
            )
        }

        let policy = LogSanitizerPolicy(preserveRules: preserveRules, redactRules: [])

        _ = LogSanitizer.sanitize("any log", policy: policy)

        #expect(receivedPreserveIdentifiers == orderedRuleIdentifiers)
        #expect(receivedRestoreIdentifiers == orderedRuleIdentifiers)
    }

    @Test(arguments: Self.randomIntegerIdentifiers)
    func shouldApplyRedactRulesInCorrectOrder(orderedRuleIdentifiers: [Int]) {
        var receivedRedactIdentifiers = [Int]()

        let redactRules = orderedRuleIdentifiers.map { id in
            RedactRule.spy(onRedact: { receivedRedactIdentifiers.append(id) })
        }

        let policy = LogSanitizerPolicy(preserveRules: [], redactRules: redactRules)

        _ = LogSanitizer.sanitize("any log", policy: policy)

        #expect(receivedRedactIdentifiers == orderedRuleIdentifiers)
    }
}

extension LogSanitizerTests.PipelineTestCase {
    static let sampleSteps = [
        LogSanitizerTests.PipelineTestCase(preserveRulesCount: 3, redactRulesCount: 1),
        LogSanitizerTests.PipelineTestCase(preserveRulesCount: 0, redactRulesCount: 0),
        LogSanitizerTests.PipelineTestCase(preserveRulesCount: 1, redactRulesCount: 1),
        LogSanitizerTests.PipelineTestCase(preserveRulesCount: 0, redactRulesCount: 2),
        LogSanitizerTests.PipelineTestCase(preserveRulesCount: 1, redactRulesCount: 0),
        LogSanitizerTests.PipelineTestCase(preserveRulesCount: 4, redactRulesCount: 3),
    ]
}

extension LogSanitizerTests {
    enum PipelineStep {
        case preserve
        case redact
        case restore
    }

    struct PipelineTestCase {
        let preserveRulesCount: Int
        let redactRulesCount: Int
        let expectedPipelineSteps: [PipelineStep]

        init(preserveRulesCount: Int, redactRulesCount: Int) {
            self.preserveRulesCount = preserveRulesCount
            self.redactRulesCount = redactRulesCount
            expectedPipelineSteps = [PipelineStep](repeating: .preserve, count: preserveRulesCount)
                + [PipelineStep](repeating: .redact, count: redactRulesCount)
                + [PipelineStep](repeating: .restore, count: preserveRulesCount)
        }
    }

    static let randomIntegerIdentifiers = [
        [6, 9],
        [5, 6, 2, 1, 5, 0, 3],
        [4, 2, 0],
        [6, 7],
    ]

    static func makeSpyPolicy(
        from testCase: PipelineTestCase,
        onPreserve: @escaping () -> Void,
        onRedact: @escaping () -> Void,
        onRestore: @escaping () -> Void
    ) -> LogSanitizerPolicy {
        let preservedRules = [PreserveRule](
            repeating: PreserveRule.spy(onPreserve: onPreserve, onRestore: onRestore),
            count: testCase.preserveRulesCount
        )

        let redactRules = [RedactRule](
            repeating: RedactRule.spy(onRedact: onRedact),
            count: testCase.redactRulesCount
        )

        return LogSanitizerPolicy(preserveRules: preservedRules, redactRules: redactRules)
    }
}

private extension PreserveRule {
    static func spy(onPreserve: @escaping () -> Void, onRestore: @escaping () -> Void) -> PreserveRule {
        PreserveRule(
            preserve: { _ in
                onPreserve()
                return []
            },
            restore: { _, _ in
                onRestore()
            }
        )
    }
}

private extension RedactRule {
    static func spy(onRedact: @escaping () -> Void) -> RedactRule {
        RedactRule(
            placeholder: "ANY_REDACT",
            redact: { _ in
                onRedact()
            }
        )
    }
}
