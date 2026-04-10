//
//  PreserveRule.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// A single preserve step in the log sanitization pipeline.
///
/// The rule temporarily replaces known-safe fragments in a log string before redaction and restores them afterward.
struct PreserveRule {
    /// Preserves known-safe fragments and returns their original values.
    let preserve: (_ input: inout String) -> [Substring]

    /// Restores values previously returned by ``preserve``.
    let restore: (_ preservedValues: [Substring], _ input: inout String) -> Void
}

extension PreserveRule {
    /// Creates a preserve rule backed by a regex pattern and generated placeholders.
    /// - Parameters:
    ///   - placeholderPrefix: Stable identifier used to build internal placeholders for preserved matches.
    ///   - pattern: Regex that matches log fragments which should survive later redaction.
    init(placeholderPrefix: String, pattern: Regex<Substring>) {
        @inline(__always)
        func makePlaceholder(for index: Int) -> String {
            "__PRESERVE_RULE_" + placeholderPrefix + "_\(index)"
        }

        preserve = { input in
            let matches = input.matches(of: pattern)

            for index in matches.indices.reversed() {
                let match = matches[index]
                input.replaceSubrange(match.range, with: makePlaceholder(for: index))
            }

            return matches.map(\.output)
        }

        restore = { preservedValues, input in
            for (index, preservedValue) in preservedValues.enumerated() {
                input.replace(
                    Regex<Substring>(verbatim: makePlaceholder(for: index)),
                    with: preservedValue,
                    maxReplacements: 1
                )
            }
        }
    }
}
