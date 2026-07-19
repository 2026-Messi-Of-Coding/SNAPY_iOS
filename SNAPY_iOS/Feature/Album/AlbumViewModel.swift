//
//  AlbumViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import Foundation
import SwiftUI
import Combine

// 빈 슬롯의 상태
enum EmptySlotState {
    case canTake
    case missed
}

@MainActor
final class AlbumViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var currentPage: Int = TimeSlot.current.rawValue
    @Published var slideDirection: SlideDirection = .none

    private let calendar: Calendar
    private var lastKnownToday: Date
    private var dayChangeTask: Task<Void, Never>?

    init(calendar: Calendar = .current, now: Date = Date()) {
        self.calendar = calendar
        let today = calendar.startOfDay(for: now)
        self._selectedDate = Published(initialValue: today)
        self.lastKnownToday = today
    }

    deinit {
        dayChangeTask?.cancel()
    }

    enum SlideDirection {
        case none, left, right
    }

    private var isToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    var dateString: String {
        selectedDate.albumDateString
    }

    /// 현재 선택된 날짜의 슬롯별 사진
    func photo(for slot: AlbumSlot) -> PhotoData? {
        if isToday {
            return PhotoStore.shared.todayPhoto(for: slot)
        } else {
            return PhotoStore.shared.selectedDatePhoto(for: slot)
        }
    }

    var streakCount: Int {
        if isToday {
            return min(PhotoStore.shared.todayPhotoCount, 5)
        } else {
            return min(PhotoStore.shared.selectedDatePhotoCount, 5)
        }
    }

    /// 찍을 수 있냐 없냐 여부
    func emptySlotState(for slot: AlbumSlot) -> EmptySlotState {
        // 과거 날짜는 더 이상 찍을 수 없음
        if !isToday { return .missed }

        let currentSlot = TimeSlot.current

        switch slot {
        case .morning:
            return currentSlot == .morning ? .canTake : .missed
        case .afternoon:
            return currentSlot == .evening ? .missed : .canTake
        case .evening:
            return .canTake
        case .extra1, .extra2:
            let count = PhotoStore.shared.todayPhotoCount
            return count < 5 ? .canTake : .missed
        }
    }

    func goToPreviousDay() {
        slideDirection = .right
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    func goToNextDay() {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        let today = calendar.startOfDay(for: Date())
        if tomorrow <= today {
            slideDirection = .left
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDate = tomorrow
            }
        }
    }

    /// 앱이 자정을 넘긴 경우, 기존에 보고 있던 오늘 앨범을 새 오늘 날짜로 갱신한다.
    func synchronizeCurrentDate() {
        let today = calendar.startOfDay(for: Date())
        defer { lastKnownToday = today }

        guard !calendar.isDate(lastKnownToday, inSameDayAs: today),
              calendar.isDate(selectedDate, inSameDayAs: lastKnownToday) else {
            return
        }

        selectedDate = today
    }

    func startObservingDayChange() {
        dayChangeTask?.cancel()
        dayChangeTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let nextDay = self.calendar.date(byAdding: .day, value: 1, to: self.calendar.startOfDay(for: Date())) ?? Date()
                let nanoseconds = UInt64(max(nextDay.timeIntervalSinceNow, 1) * 1_000_000_000)

                do {
                    try await Task.sleep(nanoseconds: nanoseconds)
                } catch {
                    return
                }

                self.synchronizeCurrentDate()
            }
        }
    }

    func stopObservingDayChange() {
        dayChangeTask?.cancel()
        dayChangeTask = nil
    }

    /// 선택된 날짜의 앨범을 서버에서 로드
    func loadSelectedDate() async {
        if isToday {
            await PhotoStore.shared.loadToday()
        } else if let albumId = PhotoStore.shared.albumId(for: selectedDate) {
            await PhotoStore.shared.loadAlbumById(albumId)
        } else {
            // monthAlbums 에 없으면 해당 월을 추가 로드 (기존 데이터 유지)
            let month = calendar.component(.month, from: selectedDate)
            await PhotoStore.shared.appendMonth(month)
            // 다시 시도
            if let albumId = PhotoStore.shared.albumId(for: selectedDate) {
                await PhotoStore.shared.loadAlbumById(albumId)
            } else {
                PhotoStore.shared.selectedDateAlbum = nil
            }
        }
    }
}
