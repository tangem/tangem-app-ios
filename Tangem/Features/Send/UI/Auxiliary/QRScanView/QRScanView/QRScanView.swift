//
//  QRScanView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct QRScanView: View {
    @ObservedObject var viewModel: QRScanViewModel

    @Environment(\.dismiss) var dismiss

    private let viewfinderCornerRadius: CGFloat = 2
    private let viewfinderPadding: CGFloat = 55

    var body: some View {
        GeometryReader { geometry in
            cameraView
                .overlay(viewfinder(screenSize: geometry.size))
                .overlay(
                    Color.clear
                        .overlay(viewfinderCrosshair(viewSize: geometry.size))
                        .overlay(textView(viewSize: geometry.size), alignment: .top)
                )
                .overlay(topButtons(), alignment: .top)
        }
        .confirmationDialog(viewModel: $viewModel.confirmationDialog)
        .ignoresSafeArea(edges: .bottom)
        // onDidAppear instead of onAppear to fix crash on IOS17 when access to the camera is restricted [REDACTED_INFO]
        .onDidAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var cameraView: some View {
        if viewModel.hasCameraAccess {
            QRScannerView(code: viewModel.code)
        } else {
            Color.black
        }
    }

    private func viewfinder(screenSize: CGSize) -> some View {
        Color.black.opacity(0.6)
            .reverseMask {
                RoundedRectangle(cornerRadius: viewfinderCornerRadius)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: max(100, screenSize.width - viewfinderPadding * 2))
            }
    }

    private func topButtons() -> some View {
        HStack(spacing: 14) {
            Button(Localization.commonClose) {
                dismiss()
            }
            .padding(7)
            .style(Fonts.Regular.body, color: .white)
            .accessibilityIdentifier(SendQRScannerAccessibilityIdentifiers.closeButton)

            Spacer()

            Button(action: viewModel.toggleFlash) {
                viewModel.isFlashActive ? Assets.flashDisabled.image : Assets.flash.image
            }
            .padding(7)
            .accessibilityIdentifier(SendQRScannerAccessibilityIdentifiers.flashToggleButton)

            Button(action: viewModel.scanFromGallery) {
                Assets.gallery.image
            }
            .padding(7)
            .accessibilityIdentifier(SendQRScannerAccessibilityIdentifiers.galleryButton)
        }
        .padding(.vertical, 21)
        .padding(.horizontal, 9)
    }

    private func viewfinderCrosshair(viewSize: CGSize) -> some View {
        RoundedRectangle(cornerRadius: viewfinderCornerRadius)
            .stroke(.white, lineWidth: 4)
            .aspectRatio(1, contentMode: .fit)
            .frame(width: max(100, viewSize.width - viewfinderPadding * 2))
            .clipShape(CrosshairShape())
    }

    private func textView(viewSize: CGSize) -> some View {
        Text(viewModel.text)
            .style(Fonts.Regular.footnote, color: .white)
            .multilineTextAlignment(.center)
            .padding(.top, 24)
            .padding(.horizontal, viewfinderPadding)
            .offset(y: viewSize.height / 2 + viewSize.width / 2 - viewfinderPadding)
            .accessibilityIdentifier(SendQRScannerAccessibilityIdentifiers.infoText)
    }
}

private struct CrosshairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addPath(cornerPath(rotation: 0, in: rect))
        path.addPath(cornerPath(rotation: 90, in: rect))
        path.addPath(cornerPath(rotation: 180, in: rect))
        path.addPath(cornerPath(rotation: 270, in: rect))
        return path
    }

    private func cornerPath(rotation: Double, in rect: CGRect) -> Path {
        // Top-left corner part of a crosshair
        var path = Path()
        path.move(to: CGPoint(x: -10, y: -10))
        path.addLine(to: CGPoint(x: -10, y: 20))
        path.addLine(to: CGPoint(x: 20, y: 20))
        path.addLine(to: CGPoint(x: 20, y: -10))
        path.closeSubpath()
        return path.rotation(.degrees(rotation)).path(in: rect)
    }
}

// MARK: - Previews

#if DEBUG

struct QRScanView_Previews_Sheet: PreviewProvider {
    @State static var code: String = ""

    static var previews: some View {
        Text("A")
            .sheet(isPresented: .constant(true)) {
                QRScanView(viewModel: .init(code: $code, text: "Please align your QR code with the square to scan it. Ensure you scan ERC-20 network address.", router: QRScanViewCoordinator(dismissAction: { _ in }, popToRootAction: { _ in })))
                    .background(
                        Image("qr_code_example")
                    )
            }
            .previewDisplayName("Sheet")
    }
}

struct QRScanView_Previews_Inline: PreviewProvider {
    @State static var code: String = ""

    static var previews: some View {
        QRScanView(viewModel: .init(code: $code, text: "Please align your QR code with the square to scan it. Ensure you scan ERC-20 network address.", router: QRScanViewCoordinator(dismissAction: { _ in }, popToRootAction: { _ in })))
            .background(
                Image("qr_code_example")
            )
            .previewDisplayName("Inline")
    }
}

#endif
