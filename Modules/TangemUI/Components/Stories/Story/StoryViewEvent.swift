//
//  StoryViewEvent.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

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
