//
//  NFTAnalytics+Entrypoint.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public extension NFTAnalytics {
    struct Entrypoint {
        // MARK: Aliases

        public typealias State = String
        public typealias CollectionsCount = Int
        public typealias NFTsCount = Int
        public typealias DummyCollectionsCount = Int

        public typealias LogCollectionsOpenClosure = (State, CollectionsCount, NFTsCount, DummyCollectionsCount) -> Void

        // MARK: Action

        let logCollectionsOpen: LogCollectionsOpenClosure

        // MARK: Init

        public init(logCollectionsOpen: @escaping LogCollectionsOpenClosure) {
            self.logCollectionsOpen = logCollectionsOpen
        }
    }
}
