//
//  ReflectionDump.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG

import Foundation

/// Renders any value as an indented, `toString`-like tree using `Mirror`. A debug-only helper for inspecting
/// the raw model a screen was assembled from — it walks the value structurally rather than relying on a
/// bespoke `CustomStringConvertible`, so it stays correct as the model evolves.
enum ReflectionDump {
    /// Backstop against a reference cycle or a pathologically deep graph blowing the stack.
    private static let maxDepth = 100

    static func text(for value: Any) -> String {
        format(value, depth: 0)
    }

    private static func format(_ value: Any, depth: Int) -> String {
        guard depth < maxDepth else {
            return "…"
        }

        let mirror = Mirror(reflecting: value)

        if mirror.displayStyle == .optional {
            guard let child = mirror.children.first else {
                return "nil"
            }
            return format(child.value, depth: depth)
        }

        // Atomic values we never want to reflect into — `Decimal`/`Date` in particular expose noisy
        // internal storage through `Mirror`, so short-circuit to their own description.
        switch value {
        case let string as String:
            return "\"\(escaped(string))\""
        case is Decimal, is Date, is URL, is UUID:
            return String(describing: value)
        default:
            break
        }

        switch mirror.displayStyle {
        case .struct, .class:
            return String(reflecting: type(of: value)) + body(fields(of: mirror), depth: depth)
        case .tuple:
            return body(fields(of: mirror), depth: depth)
        case .enum:
            return enumCase(value, mirror: mirror, depth: depth)
        case .collection, .set, .dictionary:
            return sequence(mirror.children.map(\.value), depth: depth)
        case .none, .some(.optional), .some(.foreignReference):
            return String(describing: value)
        @unknown default:
            return String(describing: value)
        }
    }

    private static func enumCase(_ value: Any, mirror: Mirror, depth: Int) -> String {
        guard let child = mirror.children.first else {
            // A case with no associated values, e.g. `confirmed`.
            return String(describing: value)
        }

        let caseName = child.label ?? String(describing: value)
        let associated = Mirror(reflecting: child.value)

        // Several / labeled associated values arrive wrapped in a tuple; splice its members directly so
        // the output reads `staking(type = …, target = …)` instead of nesting an anonymous tuple.
        if associated.displayStyle == .tuple {
            return caseName + body(fields(of: associated), depth: depth)
        }

        return caseName + body([Field(label: nil, value: child.value)], depth: depth)
    }

    private struct Field {
        let label: String?
        let value: Any
    }

    private static func fields(of mirror: Mirror) -> [Field] {
        mirror.children.map { Field(label: $0.label, value: $0.value) }
    }

    private static func body(_ fields: [Field], depth: Int) -> String {
        guard !fields.isEmpty else {
            return "()"
        }

        let padding = indentation(depth + 1)
        let lines = fields.map { field -> String in
            let formatted = format(field.value, depth: depth + 1)
            guard let label = field.label else {
                return padding + formatted
            }
            return "\(padding)\(label) = \(formatted)"
        }
        return "(\n" + lines.joined(separator: ",\n") + "\n" + indentation(depth) + ")"
    }

    private static func sequence(_ values: [Any], depth: Int) -> String {
        guard !values.isEmpty else {
            return "[]"
        }

        let padding = indentation(depth + 1)
        let lines = values.map { padding + format($0, depth: depth + 1) }
        return "[\n" + lines.joined(separator: ",\n") + "\n" + indentation(depth) + "]"
    }

    private static func escaped(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private static func indentation(_ depth: Int) -> String {
        String(repeating: "    ", count: depth)
    }
}

#endif
