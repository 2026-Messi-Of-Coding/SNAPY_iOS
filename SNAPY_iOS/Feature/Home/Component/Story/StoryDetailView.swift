//
//  StoryDetailView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/18/26.
//

import SwiftUI
import Kingfisher

/// 스토리 좋아요 상태 캐시 (앱 실행 동안 유지)
enum StoryLikeCache {
    private static var store: [String: Bool] = [:]

    static func key(storyId: Int, type: String) -> String { "\(storyId)-\(type)" }
    static func get(storyId: Int, type: String) -> Bool? { store[key(storyId: storyId, type: type)] }
    static func set(storyId: Int, type: String, liked: Bool) { store[key(storyId: storyId, type: type)] = liked }
    static func clear() { store.removeAll() }
}

struct StoryDetailView: View {
    let stories: [StoryItem]
    let initialIndex: Int
    var onStorySeen: ((Int) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: StoryDetailViewModel

    @State private var navProfileHandle: String? = nil
    @State private var showLikeSheet = false
    @State private var showReport = false
    @State private var showStoryMenu = false

    // 제스처
    @State private var dragX: CGFloat = 0.0
    @State private var isDraggingH: Bool = false
    @State private var dragY: CGFloat = 0.0
    @State private var isDraggingV: Bool = false
    @State private var isPhotoSwapped: Bool = false

    private let pageGap: CGFloat = 6

    init(stories: [StoryItem], initialIndex: Int, onStorySeen: ((Int) -> Void)? = nil) {
        self.stories = stories
        self.initialIndex = initialIndex
        self.onStorySeen = onStorySeen
        self._viewModel = StateObject(wrappedValue: StoryDetailViewModel(
            stories: stories, initialIndex: initialIndex, onStorySeen: onStorySeen
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geo in
                    ZStack {
                        Color.black.ignoresSafeArea()

                        HStack(spacing: pageGap) {
                            ForEach(0..<stories.count, id: \.self) { userIndex in
                                storyPage(
                                    for: userIndex,
                                    imageIndex: userIndex == viewModel.currentUserIndex ? viewModel.currentImageIndex : 0,
                                    size: geo.size
                                )
                                .cornerRadius(isDraggingH ? 16 : 0)
                            }
                        }
                        .offset(x: -CGFloat(viewModel.currentUserIndex) * (geo.size.width + pageGap) + dragX)
                    }
                    .offset(y: dragY)
                    .opacity(1.0 - Double(max(dragY, 0)) / 600.0)
                    .ignoresSafeArea()
                    .simultaneousGesture(longPressGesture)
                    .simultaneousGesture(combinedDragGesture(screenWidth: geo.size.width))
                }
                .background(Color.black.opacity(1.0 - Double(max(dragY, 0)) / 400.0))
                .statusBarHidden()

                if showStoryMenu { reportMenuOverlay }
            }
            .background(Color.black)
            .persistentSystemOverlays(.hidden)
            .onAppear { viewModel.onAppear(dismiss: dismiss) }
            .onDisappear { viewModel.onDisappear() }
            .onChange(of: viewModel.shouldDismiss) { _, should in
                if should { dismiss() }
            }
            .onChange(of: viewModel.currentImageIndex) { _, _ in
                viewModel.loadLikesForMyStory()
                isPhotoSwapped = false
            }
            .navigationDestination(isPresented: Binding(
                get: { navProfileHandle != nil },
                set: { if !$0 { navProfileHandle = nil; viewModel.startTimer() } }
            )) {
                if let handle = navProfileHandle {
                    FriendProfileView(
                        name: viewModel.currentStory.displayName,
                        handle: handle,
                        profileImageUrl: viewModel.currentStory.profileImage.isImageURL ? viewModel.currentStory.profileImage : nil
                    )
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showReport) {
                viewModel.isPaused = false
                viewModel.startTimer()
            } content: {
                ReportView(reportType: .STORY, targetId: "\(viewModel.currentStory.storyId)")
            }
            .sheet(isPresented: $showLikeSheet, onDismiss: { viewModel.isPaused = false }) {
                StoryLikeListSheet(likeUsers: viewModel.likeUsers)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - 신고 메뉴

    private var reportMenuOverlay: some View {
        Group {
            Color.black.opacity(0.3).ignoresSafeArea()
                .onTapGesture { showStoryMenu = false; viewModel.isPaused = false }

            VStack(spacing: 0) {
                Button {
                    showStoryMenu = false
                    showReport = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle").font(.system(size: 14))
                        Text("신고").font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
            }
            .frame(width: 100)
            .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 70).padding(.trailing, 20)
            .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .topTrailing)))
        }
    }

    // MARK: - 스토리 페이지

    @ViewBuilder
    private func storyPage(for userIndex: Int, imageIndex: Int, size: CGSize) -> some View {
        let story = stories[userIndex]
        let photos = story.photos
        let safeImageIndex = min(imageIndex, max(photos.count - 1, 0))

        ZStack {
            storyPhotoContent(photo: photos.isEmpty ? nil : photos[safeImageIndex], size: size)

            if !viewModel.hideUI {
                VStack(spacing: 0) {
                    storyTopBar(story: story, userIndex: userIndex, photos: photos)
                    Spacer()
                    LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 160).allowsHitTesting(false).padding(.bottom, -100)

                    if userIndex == viewModel.currentUserIndex {
                        StoryBottomBar(viewModel: viewModel, onShowLikeSheet: { showLikeSheet = true })
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height).clipped()
        .contentShape(Rectangle())
        .simultaneousGesture(storyTapGesture(size: size, userIndex: userIndex))
    }

    // MARK: - 상단 바

    @ViewBuilder
    private func storyTopBar(story: StoryItem, userIndex: Int, photos: [StoryPhotoSet]) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<photos.count, id: \.self) { idx in
                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.3)).frame(height: 2.5)
                            RoundedRectangle(cornerRadius: 2).fill(Color.white)
                                .frame(width: userIndex == viewModel.currentUserIndex ? viewModel.barWidth(for: idx, totalWidth: barGeo.size.width) : 0, height: 2.5)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(.horizontal, 12).allowsHitTesting(false)

            HStack(spacing: 12) {
                Button {
                    if story.username != viewModel.myHandle {
                        viewModel.stopTimer()
                        navProfileHandle = story.username
                    }
                } label: {
                    HStack(spacing: 12) {
                        profileImageView(name: story.profileImage)
                            .frame(width: 40, height: 40).clipped().clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(story.displayName).font(.system(size: 14, weight: .bold)).foregroundColor(.textWhite)
                            Text(story.username).font(.system(size: 12, weight: .medium)).foregroundColor(.customGray200)
                        }
                    }
                }
                .buttonStyle(.plain)

                if let timeText = viewModel.currentPhotoTimeText(for: story, imageIndex: userIndex == viewModel.currentUserIndex ? viewModel.currentImageIndex : 0), !timeText.isEmpty {
                    Text(timeText).font(.system(size: 13)).foregroundColor(.customGray200)
                        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1).padding(.leading, 4)
                }

                Spacer()

                HStack(spacing: 2) {
                    if story.username != viewModel.myHandle {
                        Button { viewModel.isPaused = true; showStoryMenu = true } label: {
                            Image(systemName: "ellipsis").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                .frame(width: 36, height: 36).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .highPriorityGesture(TapGesture().onEnded { viewModel.isPaused = true; showStoryMenu = true })
                    }

                    Button { animateDismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 20, weight: .medium)).foregroundColor(.white)
                            .frame(width: 36, height: 36).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .highPriorityGesture(TapGesture().onEnded { animateDismiss() })
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.top, 16)
    }

    // MARK: - 이미지

    @ViewBuilder
    private func storyPhotoContent(photo: StoryPhotoSet?, size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            // 풀사이즈: back 이미지
            if let backUrl = photo?.backImageUrl, let url = URL(string: backUrl) {
                KFImage(url).resizable().placeholder { Color.customGray500 }.fade(duration: 0.2)
                    .scaledToFill().frame(width: size.width, height: size.height).clipped()
                    .opacity(isPhotoSwapped ? 0 : 1)
            } else {
                Color.customGray500.frame(width: size.width, height: size.height)
            }

            // 풀사이즈: front 이미지 (스왑 시 표시)
            if let frontUrl = photo?.frontImageUrl, let url = URL(string: frontUrl) {
                KFImage(url).resizable().placeholder { Color.customGray500 }.fade(duration: 0.2)
                    .scaledToFill().frame(width: size.width, height: size.height).clipped()
                    .opacity(isPhotoSwapped ? 1 : 0)
            }

            // PIP (탭 불가능한 표시 전용 - 탭 전환은 storyPage에서 처리)
            if let frontUrl = photo?.frontImageUrl, let fUrl = URL(string: frontUrl),
               let backUrl = photo?.backImageUrl, let bUrl = URL(string: backUrl) {
                ZStack {
                    KFImage(fUrl).resizable().placeholder { Color.customGray500 }.fade(duration: 0.2)
                        .scaledToFill().opacity(isPhotoSwapped ? 0 : 1)
                    KFImage(bUrl).resizable().placeholder { Color.customGray500 }.fade(duration: 0.2)
                        .scaledToFill().opacity(isPhotoSwapped ? 1 : 0)
                }
                .frame(width: 130, height: 180).clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .padding(.top, 80).padding(.leading, 14)
                .allowsHitTesting(false)
            } else if let frontUrl = photo?.frontImageUrl, let url = URL(string: frontUrl) {
                KFImage(url).resizable().placeholder { Color.customGray500 }.fade(duration: 0.2)
                    .scaledToFill().frame(width: 130, height: 180).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.3), lineWidth: 1))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.top, 80).padding(.leading, 14)
            }
        }
    }

    @ViewBuilder
    private func profileImageView(name: String) -> some View {
        if name.isImageURL, let url = URL(string: name) {
            KFImage(url).resizable().placeholder { Image("Profile_img").resizable().scaledToFill() }.fade(duration: 0.2).scaledToFill()
        } else if !name.isEmpty {
            Image(name).resizable().scaledToFill()
        } else {
            Image("Profile_img").resizable().scaledToFill()
        }
    }

    // MARK: - 헬퍼

    private func animateDismiss() {
        withAnimation(.easeOut(duration: 0.3)) { dragY = 1000 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dismiss() }
    }

    // MARK: - 제스처

    private func storyTapGesture(size: CGSize, userIndex: Int) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                guard userIndex == viewModel.currentUserIndex else { return }

                let location = value.location
                let pipRect = CGRect(x: 14, y: 80, width: 130, height: 180)
                let topReservedHeight: CGFloat = 96
                let bottomReservedHeight: CGFloat = 170

                if pipRect.contains(location) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.15, dampingFraction: 1)) {
                        isPhotoSwapped.toggle()
                    }
                    return
                }

                guard location.y >= topReservedHeight,
                      location.y <= size.height - bottomReservedHeight else {
                    return
                }

                if location.x < size.width * 0.25 {
                    viewModel.goToPrevious()
                } else {
                    viewModel.goToNext()
                }
            }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                if case .second(true, _) = value {
                    viewModel.isPaused = true; viewModel.hideUI = true
                }
            }
            .onEnded { _ in viewModel.isPaused = false; viewModel.hideUI = false }
    }

    private func combinedDragGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                let hDrag = abs(value.translation.width)
                let vDrag = abs(value.translation.height)
                if !isDraggingH && !isDraggingV {
                    if vDrag > hDrag && value.translation.height > 0 { isDraggingV = true }
                    else if hDrag > vDrag { isDraggingH = true }
                }
                if isDraggingV { dragY = max(value.translation.height, 0); viewModel.isPaused = true }
                else if isDraggingH { dragX = value.translation.width; viewModel.isPaused = true }
            }
            .onEnded { value in
                if isDraggingV {
                    if dragY > 120 { animateDismiss() }
                    else { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { dragY = 0 }; viewModel.isPaused = false }
                } else if isDraggingH {
                    let threshold: CGFloat = screenWidth * 0.25
                    if value.translation.width < -threshold && viewModel.currentUserIndex < stories.count - 1 {
                        withAnimation(.easeOut(duration: 0.35)) { viewModel.currentUserIndex += 1; dragX = 0 }
                        viewModel.currentImageIndex = 0; viewModel.progress = 0; viewModel.isLiked = false; viewModel.isPaused = false; viewModel.startTimer()
                    } else if value.translation.width > threshold && viewModel.currentUserIndex > 0 {
                        withAnimation(.easeOut(duration: 0.35)) { viewModel.currentUserIndex -= 1; dragX = 0 }
                        viewModel.currentImageIndex = stories[viewModel.currentUserIndex].photos.count - 1; viewModel.progress = 0; viewModel.isLiked = false; viewModel.isPaused = false; viewModel.startTimer()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { dragX = 0 }; viewModel.isPaused = false
                    }
                }
                isDraggingH = false; isDraggingV = false
            }
    }
}

#Preview("StoryDetail") {
    StoryDetailView(
        stories: [
            StoryItem(storyId: 1, profileImage: "Profile_img", bannerImage: "Mock_img1",
                      displayName: "은찬", username: "silver_c_Id",
                      photos: [
                        StoryPhotoSet(type: "MORNING", frontImageUrl: "Mock_img1", backImageUrl: "Mock_img1", createdAt: nil),
                        StoryPhotoSet(type: "LUNCH", frontImageUrl: "Mock_img2", backImageUrl: "Mock_img2", createdAt: nil),
                      ], createdAt: nil, isSeen: false),
        ],
        initialIndex: 0
    )
}
