//
//  ImageViewerView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
import Kingfisher

struct ImageViewerView: View {
    let image: UIImage?
    let imageUrl: String?
    let assetName: String
    var horizontalPadding: CGFloat = 0
    var isCircle: Bool = false
    var isFreeForm: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var imageFrame: CGSize = .zero
    @State private var screenSize: CGSize = .zero

    private let maxZoom: CGFloat = 5.0

    var body: some View {
        GeometryReader { screen in
            ZStack {
                Color.black.opacity(1.0 - min(abs(dragOffset.height) / 300.0, 0.5))
                    .ignoresSafeArea()

                Group {
                    if let uiImage = image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: isFreeForm ? .fit : .fill)
                    } else if let url = imageUrl, let imgUrl = URL(string: url) {
                        KFImage(imgUrl)
                            .resizable()
                            .placeholder { Color.customDarkGray.overlay(ProgressView().tint(.white)) }
                            .fade(duration: 0.2)
                            .aspectRatio(contentMode: isFreeForm ? .fit : .fill)
                    } else {
                        Image(assetName)
                            .resizable()
                            .aspectRatio(contentMode: isFreeForm ? .fit : .fill)
                    }
                }
                .frame(
                    width: isFreeForm ? nil : (isCircle ? 300 : nil),
                    height: isFreeForm ? nil : (isCircle ? 300 : 230)
                )
                .frame(maxWidth: .infinity, maxHeight: isFreeForm ? .infinity : nil)
                .clipShape(isCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: isFreeForm ? 0 : 16)))
                .padding(.horizontal, horizontalPadding)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear { imageFrame = geo.size }
                    }
                )
                .scaleEffect(scale)
                .offset(x: offset.width, y: offset.height + dragOffset.height)
                .opacity(1.0 - min(abs(dragOffset.height) / 300.0, 0.5))

            }
            .onAppear { screenSize = screen.size }
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let newScale = min(lastScale * value.magnification, maxZoom)
                        scale = newScale
                    }
                    .onEnded { _ in
                        if scale < 1.0 {
                            resetZoom()
                        } else {
                            lastScale = scale
                            clampOffset()
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if scale > 1.0 {
                            let rawOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            // 드래그 중 실시간 경계 제한
                            offset = clampedOffset(rawOffset)
                        } else {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { _ in
                        if scale > 1.0 {
                            lastOffset = offset
                        } else {
                            if abs(dragOffset.height) > 120 {
                                dismiss()
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                }
                            }
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        if scale > 1.0 {
                            resetZoom()
                        } else {
                            withAnimation(.spring()) {
                                scale = 2
                                lastScale = 2
                            }
                        }
                    }
            )
        }
    }

    // MARK: - 줌 리셋

    private func resetZoom() {
        withAnimation(.spring()) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }

    // MARK: - 경계 제한 (값 반환)

    private func clampedOffset(_ raw: CGSize) -> CGSize {
        let imgW = imageFrame.width > 0 ? imageFrame.width : screenSize.width
        let imgH = imageFrame.height > 0 ? imageFrame.height : screenSize.height
        let scrW = screenSize.width > 0 ? screenSize.width : imgW
        let scrH = screenSize.height > 0 ? screenSize.height : imgH

        let maxX = max((imgW * scale - scrW) / 2, 0)
        let maxY = max((imgH * scale - scrH) / 2, 0)

        return CGSize(
            width: min(max(raw.width, -maxX), maxX),
            height: min(max(raw.height, -maxY), maxY)
        )
    }

    // MARK: - 현재 offset 클램프 (애니메이션)

    private func clampOffset() {
        let clamped = clampedOffset(offset)
        if clamped != offset {
            withAnimation(.spring()) {
                offset = clamped
            }
        }
        lastOffset = clamped
    }
}
