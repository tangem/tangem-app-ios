//
//  AuxiliaryViewAnimatable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol AuxiliaryViewAnimatable: AnyObject {
    var didFinishAnimationToSummary: Bool { get set }
    var animatingAuxiliaryViewsOnAppear: Bool { get set }

    func onViewAppeared()
    func onViewDisappeared()
    func setAnimatingAuxiliaryViewsOnAppear()
}

extension AuxiliaryViewAnimatable {
    func onViewAppeared() {
        print("zzz onappear")
        didFinishAnimationToSummary = false

        if animatingAuxiliaryViewsOnAppear {
            withAnimation(SendView.Constants.defaultAnimation) {
                animatingAuxiliaryViewsOnAppear = false
            }
        }
    }

    func onViewDisappeared() {
        print("zzz ondisappear")
        didFinishAnimationToSummary = true
    }

    func setAnimatingAuxiliaryViewsOnAppear() {
        print("zzz setAnimatingAuxiliaryViewsOnAppear", didFinishAnimationToSummary)
        if didFinishAnimationToSummary {
            animatingAuxiliaryViewsOnAppear = true
        } else {
            animatingAuxiliaryViewsOnAppear = false
        }
    }
}
