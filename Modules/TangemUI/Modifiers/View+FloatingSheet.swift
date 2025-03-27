//
//  View+FloatingSheet.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    func floatingSheet<SheetContent: View>(isPresented: Binding<Bool>, @ViewBuilder sheetContent: () -> SheetContent) -> some View {
        FloatingSheetView(isPresented: isPresented, hostContent: self, sheetContent: sheetContent)
    }
}

// MARK: - FloatingSheetConfiguration setters

public extension View {
    func floatingSheetMinHeightFraction(_ minHeightFraction: CGFloat) -> some View {
        environment(\.floatingSheetConfiguration.minHeightFraction, minHeightFraction)
    }

    func floatingSheetMaxHeightFraction(_ maxHeightFraction: CGFloat) -> some View {
        environment(\.floatingSheetConfiguration.maxHeightFraction, maxHeightFraction)
    }

    func floatingSheetBackgroundColor(_ sheetBackgroundColor: Color) -> some View {
        environment(\.floatingSheetConfiguration.sheetBackgroundColor, sheetBackgroundColor)
    }

    func floatingSheetBackgroundInteractionBehavior(
        _ backgroundInteractionBehavior: FloatingSheetConfiguration.BackgroundInteractionBehavior
    ) -> some View {
        environment(\.floatingSheetConfiguration.backgroundInteractionBehavior, backgroundInteractionBehavior)
    }

    func floatingSheetVerticalSwipeBehavior(_ verticalSwipeBehavior: FloatingSheetConfiguration.VerticalSwipeBehavior) -> some View {
        environment(\.floatingSheetConfiguration.verticalSwipeBehavior, verticalSwipeBehavior)
    }

    func floatingSheetKeyboardHandlingEnabled(_ keyboardHandlingEnabled: Bool) -> some View {
        environment(\.floatingSheetConfiguration.keyboardHandlingEnabled, keyboardHandlingEnabled)
    }
}
