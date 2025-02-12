//
//  StoryViewEvent.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]
enum StoryViewEvent {
    case viewDidAppear
    case viewDidDisappear

    case viewInteractionPaused
    case viewInteractionResumed

    case longTapPressed
    case longTapEnded

    case tappedForward
    case tappedBackward

    case willTransitionBackFromOtherStory
}
