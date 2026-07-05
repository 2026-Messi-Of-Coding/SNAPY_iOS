//
//  PublishPreviewSheet.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI
import Kingfisher

struct PublishPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var homeViewModel: HomeViewModel
    @StateObject private var viewModel = PublishPreviewViewModel()

    @State private var showConfirmDialog = false

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.todayPhotos.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.width > 80 && abs(value.translation.height) < 100 { dismiss() }
            }
        )
        .task { await viewModel.loadToday() }
        .alert("아직 남은 시간대가 있어요", isPresented: $showConfirmDialog) {
            Button("취소", role: .cancel) { }
            Button("게시할게요") {
                viewModel.publish(homeViewModel: homeViewModel) { dismiss() }
            }
        } message: {
            Text(viewModel.upcomingSlotWarningMessage)
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("게시하기")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textWhite)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 52)
    }

    // MARK: - 콘텐츠

    private var contentView: some View {
        VStack(spacing: 0) {
            Text("오늘의 히스토리")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.textWhite)
                .padding(.top, 32).padding(.bottom, 44)

            GeometryReader { geo in
                let cardWidth = geo.size.width * 0.72
                let cardHeight = cardWidth * 1.45
                let sidePadding = (geo.size.width - cardWidth) / 2

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.todayPhotos, id: \.id) { photo in
                            PublishPhotoCard(photo: photo)
                                .frame(width: cardWidth, height: cardHeight)
                                .scrollTransition(axis: .horizontal) { content, phase in
                                    content.scaleEffect(phase.isIdentity ? 1.0 : 0.94)
                                        .opacity(phase.isIdentity ? 1.0 : 0.55)
                                }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, sidePadding)
                }
                .scrollTargetBehavior(.viewAligned)
                .frame(width: geo.size.width, height: cardHeight)
            }
            .aspectRatio(1 / (0.72 * 1.45), contentMode: .fit)

            Spacer()

            if viewModel.isAlreadyPublished {
                Text("오늘은 이미 게시했어요!\n내일 다시 만나요")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.customGray300)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24).padding(.top, 6).padding(.bottom, 12)
                    .lineSpacing(4)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.customRed)
                    .padding(.bottom, 6)
            }

            Button {
                if viewModel.shouldShowConfirmDialog() {
                    showConfirmDialog = true
                } else if !viewModel.isAlreadyPublished {
                    viewModel.publish(homeViewModel: homeViewModel) { dismiss() }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isPublishing {
                        ProgressView().tint(.textWhite)
                    } else {
                        Image(systemName: "paperplane").font(.system(size: 20, weight: .medium))
                        Text(viewModel.isAlreadyPublished ? "오늘 게시 완료" : "게시하기")
                            .font(.system(size: 22, weight: .semibold))
                    }
                }
                .foregroundColor(viewModel.isAlreadyPublished ? .customGray300 : .textWhite)
                .frame(maxWidth: .infinity).frame(height: 52)
            }
            .disabled(viewModel.isPublishing || viewModel.todayAlbumId == nil || viewModel.isAlreadyPublished)
            .padding(.horizontal, 24).padding(.bottom, 70)
        }
    }

    // MARK: - 빈 상태

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("Crying_img").resizable().scaledToFit().frame(width: 80, height: 80)
            Text("오늘 찍은 사진이 없습니다")
                .font(.system(size: 18, weight: .semibold)).foregroundColor(.customGray300)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 사진 카드

private struct PublishPhotoCard: View {
    let photo: PhotoData
    @State private var isSwapped = false

    var body: some View {
        GeometryReader { geo in
            let pipWidth = geo.size.width * 0.32
            let pipHeight = geo.size.width * 0.42

            ZStack(alignment: .topLeading) {
                // 풀사이즈: back 이미지
                KFImage(URL(string: photo.backImageUrl ?? ""))
                    .resizable()
                    .placeholder {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(ProgressView().tint(.white))
                    }
                    .fade(duration: 0.2)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .opacity(isSwapped ? 0 : 1)

                // 풀사이즈: front 이미지 (스왑 시 표시)
                KFImage(URL(string: photo.frontImageUrl ?? ""))
                    .resizable()
                    .placeholder {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(ProgressView().tint(.white))
                    }
                    .fade(duration: 0.2)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .opacity(isSwapped ? 1 : 0)

                // PIP: 양쪽 이미지를 겹쳐서 크로스페이드
                DraggablePIP(containerSize: geo.size, pipWidth: pipWidth, pipHeight: pipHeight, padding: 12) {
                    ZStack {
                        KFImage(URL(string: photo.frontImageUrl ?? ""))
                            .resizable()
                            .placeholder { Color.white.opacity(0.1) }
                            .fade(duration: 0.2)
                            .aspectRatio(contentMode: .fill)
                            .opacity(isSwapped ? 0 : 1)
                        KFImage(URL(string: photo.backImageUrl ?? ""))
                            .resizable()
                            .placeholder { Color.white.opacity(0.1) }
                            .fade(duration: 0.2)
                            .aspectRatio(contentMode: .fill)
                            .opacity(isSwapped ? 1 : 0)
                    }
                } onTap: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.15, dampingFraction: 1)) {
                        isSwapped.toggle()
                    }
                }
            }
        }
    }
}

#Preview("PublishPreviewView") {
    NavigationStack {
        PublishPreviewView(homeViewModel: HomeViewModel())
    }
}
