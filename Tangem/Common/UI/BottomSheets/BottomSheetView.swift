//
//  BottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct BottomSheetView<Content: View>: View {
    
    var isPresented: Published<Bool>.Publisher
    var hideBottomSheetCallback: () -> ()
    var content: Content
    
    @State private var _isPresented = false
    
    init(isPresented: Published<Bool>.Publisher, hideBottomSheetCallback: @escaping () -> (), @ViewBuilder content: () -> Content) {
        self.isPresented = isPresented
        self.hideBottomSheetCallback = hideBottomSheetCallback
        self.content = content()
    }
    
    @State private var backgroundOpacity: Double = 0
    @State private var sheetOffset: CGFloat = UIScreen.main.bounds.height
    @State private var lastDragValue: DragGesture.Value?
    @State private var sheetSize: CGSize = .init(width: UIScreen.main.bounds.width, height: 570)
    
    private let backgroundVisibleOpacity: Double = 0.5
    private let sheetVisibleOffset: CGFloat = 0
    private let defaultAnimDuration: Double = 0.22
    private let screenSize: CGSize = UIScreen.main.bounds.size
    
    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                guard _isPresented else { return }
                
                lastDragValue = value
                let currentDistanceToBottomEdge = screenSize.height - value.location.y
                let startDisctanceToBottomEdge = screenSize.height - value.startLocation.y
                backgroundOpacity = min(backgroundVisibleOpacity, backgroundVisibleOpacity * Double(currentDistanceToBottomEdge / startDisctanceToBottomEdge))
                sheetOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                guard _isPresented else { return }
                
                let shouldDismiss = value.predictedEndTranslation.height > UIScreen.main.bounds.height / 3
                let speed: Double = speed(for: value)
                
                if(speed > 200) || shouldDismiss {
                    let distanceToBottomEdge = (screenSize.height - value.location.y)
                    let animDuration = min(defaultAnimDuration, Double(distanceToBottomEdge) / speed)
                    hideBottomSheet(with: animDuration)
                } else {
                    showBottomSheet(with: defaultAnimDuration)
                }
            }
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomLeading) {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxHeight: UIScreen.main.bounds.height)
                    .opacity(backgroundOpacity)
                    .onTapGesture {
                        hideBottomSheet(with: defaultAnimDuration)
                    }
                VStack {
                    Rectangle()
                        .frame(size: .init(width: 33, height: 5))
                        .cornerRadius(2.5)
                        .padding(.top, 12)
                        .foregroundColor(.tangemGrayLight4)
                    content
                    TangemButton(title: "common_close") {
                        hideBottomSheet(with: defaultAnimDuration)
                    }
                    .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt, layout: .wide))
                    .padding(.bottom, 16 + proxy.safeAreaInsets.bottom)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10, corners: [.topLeft, .topRight])
                .gesture(dragGesture)
                .offset(x: 0, y: sheetOffset)
                .readSize { size in
                    sheetSize = size
                }
            }
            .frame(alignment: .bottom)
            .edgesIgnoringSafeArea(.bottom)
        }
        .onReceive(isPresented) { isPresented in
            _isPresented = isPresented
            
            guard isPresented else {
                return
            }
            
            if sheetOffset > 0 {
                showBottomSheet(with: defaultAnimDuration)
            }
        }
    }
    
    
    
    private func speed(for value: DragGesture.Value) -> Double {
        guard let lastDragValue = lastDragValue else { return 0 }
        
        let timeDiff = value.time.timeIntervalSince(lastDragValue.time)
        let speed: Double = Double(value.location.y - lastDragValue.location.y) / timeDiff
        
        return speed
    }
    
    private func showBottomSheet(with duration: TimeInterval) {
        withAnimation(.linear(duration: duration)) {
            sheetOffset = 0
            backgroundOpacity = backgroundVisibleOpacity
        }
    }
    
    private func hideBottomSheet(with duration: TimeInterval) {
        withAnimation(.linear(duration: duration)) {
            sheetOffset = sheetSize.height
            backgroundOpacity = 0
        }
        hideBottomSheetCallback()
    }
}

class BottomSheetPreviewProvider: ObservableObject {
    @Published var isBottomSheetPresented: Bool = false
}

struct BottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        AddressQrBottomSheetPreviewView(model: BottomSheetPreviewProvider())
//            .previewGroup(devices: [.iPhone12Pro])
    }
}
