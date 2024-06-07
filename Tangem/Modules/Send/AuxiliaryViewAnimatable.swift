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
    var didProperlyDisappear: Bool { get set }
    var animatingAuxiliaryViewsOnAppear: Bool { get set }

    func onAuxiliaryViewAppear()
    func onAuxiliaryViewDisappear()
    func setAnimatingAuxiliaryViewsOnAppear()
}

extension AuxiliaryViewAnimatable {
    func onAuxiliaryViewAppear() {
        didProperlyDisappear = false
        print(#function, "\(self) ->>", "set didProperlyDisappear true")
        if animatingAuxiliaryViewsOnAppear {
            withAnimation(SendView.Constants.defaultAnimation) {
                print(#function, "\(self) ->>", "set withAnimation animatingAuxiliaryViewsOnAppear false")
                animatingAuxiliaryViewsOnAppear = false
            }
        }
    }

    func onAuxiliaryViewDisappear() {
        print(#function, "\(self) ->>", "set didProperlyDisappear true")
        didProperlyDisappear = true
    }

    func setAnimatingAuxiliaryViewsOnAppear() {
        print(#function, "\(self) ->>", "set animatingAuxiliaryViewsOnAppear = didProperlyDisappear = \(didProperlyDisappear)")
        animatingAuxiliaryViewsOnAppear = didProperlyDisappear
    }
}
