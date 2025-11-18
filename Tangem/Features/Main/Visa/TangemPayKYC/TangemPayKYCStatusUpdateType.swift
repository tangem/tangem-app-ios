//
//  TangemPayKYCStatusUpdateType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum TangemPayKYCStatusUpdateType: String, CaseIterable {
    case onReady
    case onInitialized
    case onStepInitiated
    case onLivenessCompleted
    case onStepCompleted
    case onApplicantLoaded
    case onApplicantSubmitted
    case onError
    case onApplicantStatusChanged
    case onApplicantResubmitted
    case onApplicantActionLoaded
    case onApplicantActionSubmitted
    case onApplicantActionStatusChanged
    case onApplicantActionCompleted
    case moduleResultPresented
    case onResize
    case onVideoIdentCallStarted
    case onVideoIdentModeratorJoined
    case onVideoIdentCompleted
    case onUploadError
    case onUploadWarning
    case onNavigationUiControlsStateChanged
    case onApplicantLevelChanged
}
