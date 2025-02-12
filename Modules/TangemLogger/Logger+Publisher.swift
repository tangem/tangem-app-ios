//
//  Logger+Publisher.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

public extension Publisher {
    func logging(
        _ prefix: String = "",
        to logger: Logger = CombineLog,
        options: Publishers.LogOptions = .default,
        mapOutput: ((Output) -> String)? = nil
    ) -> Publishers.HandleEvents<Self> {
        handleEvents { subscription in
            if options.contains(.subscription) {
                logger.debug("\(prefix)subscription: \(subscription)")
            }
        } receiveOutput: { value in
            if options.contains(.output) {
                logger.debug("\(prefix)value: \(mapOutput.map { $0(value) } ?? "\(value)")")
            }
        } receiveCompletion: { completion in
            if options.contains(.completion) {
                logger.debug("\(prefix)completion: \(completion)")
            }
        } receiveCancel: {
            if options.contains(.cancel) {
                logger.debug("\(prefix)cancel")
            }
        } receiveRequest: { request in
            if options.contains(.request) {
                logger.debug("\(prefix)request: \(request)")
            }
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
