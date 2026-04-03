//
//  MainQRScanView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MainQRScanView: View {
    @ObservedObject var viewModel: MainQRScanViewModel

    var body: some View {
        ZStack {
            cameraView
                .ignoresSafeArea()
                .animation(.default, value: viewModel.hasCameraAccess)

            dimmingOverlay

            VStack {
                navigationBar
                Spacer()
            }

            scannerContent
        }
        .confirmationDialog(viewModel: $viewModel.confirmationDialog)
        .onDidAppear(perform: viewModel.onViewAppear)
    }

    // MARK: - Camera

    @ViewBuilder
    private var cameraView: some View {
        if viewModel.hasCameraAccess {
            QRScannerView(
                code: Binding(
                    get: { "" },
                    set: { qrCode in
                        viewModel.onQRCodeScanned(qrCode)
                    }
                ),
                shouldDismissOnSuccess: false,
                shouldDismissOnFailure: false,
                onScanningFailure: viewModel.onScannerFailure
            )
            .transition(.opacity)
        } else {
            Color.black
                .transition(.opacity)
        }
    }

    // MARK: - Dimming Overlay

    private var dimmingOverlay: some View {
        Colors.Overlays.overlaySecondary
            .ignoresSafeArea()
            .reverseMask(alignment: .center) {
                scannerRectangle(fillColor: .black)
            }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 14) {
            Button(action: viewModel.onCloseTapped) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Colors.Text.constantWhite)
                    .contentShape(Rectangle())
            }
            .padding(7)

            Spacer()

            Button(action: viewModel.toggleFlash) {
                (viewModel.isFlashActive ? Assets.flashDisabled.image : Assets.flash.image)
                    .foregroundColor(Colors.Text.constantWhite)
            }
            .padding(7)
        }
        .padding(.vertical, 21)
        .padding(.horizontal, 9)
    }

    // MARK: - Scanner Content

    private var scannerContent: some View {
        scannerRectangle()
            .overlay {
                CornerArcsBorder(
                    cornerSize: CGSize(width: 30, height: 30),
                    cornerRadius: 16,
                    lineWidth: 4
                )
                .stroke(Colors.Icon.constant, lineWidth: 4)
                .padding(.horizontal, 38)
                .padding(.vertical, -2)
            }
            .overlay(alignment: .top) {
                hintView
                    .padding(.bottom, 48)
                    .alignmentGuide(.top) { dimension in
                        dimension[.bottom]
                    }
            }
            .overlay(alignment: .bottom) {
                pasteButton
                    .padding(.top, 32)
                    .alignmentGuide(.bottom) { dimension in
                        dimension[.top]
                    }
            }
    }

    private var hintView: some View {
        Text(viewModel.hintText)
            .style(Fonts.Regular.subheadline, color: Colors.Text.constantWhite)
            .frame(maxWidth: 200)
            .multilineTextAlignment(.center)
    }

    private var pasteButton: some View {
        PasteButton(payloadType: String.self) { clipboardStrings in
            Task { @MainActor in
                viewModel.onPasteFromClipboard(clipboardStrings.first)
            }
        }
        .labelStyle(.titleAndIcon)
        .tint(.clear)
    }

    // MARK: - Helpers

    private func scannerRectangle(fillColor: Color = .clear) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(fillColor)
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 40)
    }
}
