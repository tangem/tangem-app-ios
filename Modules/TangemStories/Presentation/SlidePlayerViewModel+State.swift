//
//  SlidePlayerViewModel+State.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public extension SlidePlayerViewModel {
    enum State: Equatable {
        case preparing
        case playing
        case buffering
        case completed
    }
}
