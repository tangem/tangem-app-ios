//
//  Logger+Publisher.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

public extension Publisher {
    /// Log to console wth specify logger.
    /// ```
    /// Just(1, 2, 3)
    ///     .logging()
    ///
    ///     // Will print to console as
    ///     // value: 1
    ///     // value: 2
    ///     // value: 3
    /// ```
    /// - Parameters:
    ///   - prefix: Some which will be added before message
    ///   - logger: The logger which one will be use. Default  - `CombineLog`
    ///   - options: Supports two way
    ///   1. `.default` - will be logged any event like `[output, completion, cancel]`
    ///   2. `.verbose` - will be logged all events `[subscription, output, completion, cancel, request]`
    ///   - mapOutput: You can map an `Output` to see most needed value.
    /// - Returns: A publisher that performs the specified closures when publisher events occur.
    func logging(
        _ prefix: String? = nil,
        to logger: Logger = CombineLog,
        options: Publishers.LogOptions = .default,
        mapOutput: ((Output) -> Any)? = nil
    ) -> Publishers.HandleEvents<Self> {
        func log(_ action: String, _ value: Any? = nil) {
            let args = [prefix, action, value.map(String.init(describing:))]
            logger.debug(args.compactMap { $0 }.joined(separator: ": "))
        }

        return handleEvents { subscription in
            options.contains(.subscription) ? log("subscription") : ()
        } receiveOutput: { value in
            options.contains(.output) ? log("value", mapOutput.map { $0(value) } ?? value) : ()
        } receiveCompletion: { completion in
            options.contains(.completion) ? log("completion", completion) : ()
        } receiveCancel: {
            options.contains(.cancel) ? log("cancel") : ()
        } receiveRequest: { request in
            options.contains(.request) ? log("request", request) : ()
        }
    }
}

public extension Publishers {
    struct LogOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let subscription = LogOptions(rawValue: 1 << 0)
        public static let output = LogOptions(rawValue: 1 << 1)
        public static let completion = LogOptions(rawValue: 1 << 2)
        public static let cancel = LogOptions(rawValue: 1 << 3)
        public static let request = LogOptions(rawValue: 1 << 4)

        /// Only basic components will be logged.
        public static let `default`: LogOptions = [output, completion, cancel]
        /// All components will be logged.
        public static let verbose: LogOptions = [subscription, output, completion, cancel, request]
    }
}

// MARK: - Logger + TextOutputStream

extension Logger: TextOutputStream {
    public func write(_ string: String) {
        debug(string)
    }
}
