//
//  TonConnectSSEParser.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// One `text/event-stream` event.
public struct TonConnectSSEEvent: Equatable, Sendable {
    public let id: String?
    public let event: String?
    public let data: String

    public init(id: String?, event: String?, data: String) {
        self.id = id
        self.event = event
        self.data = data
    }

    /// Bridge keep-alives: `event: heartbeat` (legacy) or `event: message` + `data: heartbeat`.
    public var isHeartbeat: Bool {
        event == "heartbeat" || data == "heartbeat"
    }
}

/// Incremental line-oriented Server-Sent-Events parser (WHATWG EventSource algorithm, subset).
///
/// Feed it lines without their terminator; an event is emitted on every empty line. Comment lines
/// (`:`) and unknown fields are ignored, `data:` lines are joined with `\n`.
public struct TonConnectSSEParser: Sendable {
    private var id: String?
    private var event: String?
    private var dataLines: [String] = []

    public init() {}

    /// Returns a complete event when `line` terminates one, `nil` otherwise.
    public mutating func feed(line rawLine: String) -> TonConnectSSEEvent? {
        let line = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine

        if line.isEmpty {
            return flush()
        }

        if line.hasPrefix(":") {
            return nil
        }

        let field: Substring
        let value: Substring
        if let colon = line.firstIndex(of: ":") {
            field = line[..<colon]
            var rest = line[line.index(after: colon)...]
            if rest.hasPrefix(" ") { rest = rest.dropFirst() }
            value = rest
        } else {
            field = Substring(line)
            value = ""
        }

        switch field {
        case "id":
            // Per spec, an id containing NUL is ignored.
            if !value.contains("\0") { id = String(value) }
        case "event":
            event = String(value)
        case "data":
            dataLines.append(String(value))
        default:
            break
        }

        return nil
    }

    private mutating func flush() -> TonConnectSSEEvent? {
        defer {
            event = nil
            dataLines = []
        }

        guard !dataLines.isEmpty else {
            return nil
        }

        // `id` is sticky across events until the stream sets a new one, matching EventSource semantics.
        return TonConnectSSEEvent(id: id, event: event, data: dataLines.joined(separator: "\n"))
    }
}
