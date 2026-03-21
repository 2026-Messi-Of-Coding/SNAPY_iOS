//
//  PhotoStore.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/21/26.
//

import Foundation
import SwiftUI
import Combine

struct SavedPhoto: Identifiable {
    let id = UUID()
    let frontImage: UIImage?
    let backImage: UIImage?
//    let timeSlot: TimeSlot
    let capturedAt: Date
}

struct DailyAlbum: Identifiable {
    let id = UUID()
    let date: Date
    var photos: [SavedPhoto]

//    var dateString: String {
//        date.koreanDateString
//    }
}

@MainActor
final class PhotoStore: ObservableObject {
    static let shared = PhotoStore()

    @Published var dailyAlbums: [DailyAlbum] = []

    private init() {}

    var todayAlbum: DailyAlbum? {
        dailyAlbums.first { Calendar.current.isDateInToday($0.date) }
    }

    func album(for date: Date) -> DailyAlbum? {
        dailyAlbums.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

//    func savePhotos(_ photos: [(front: UIImage?, back: UIImage?)]) {
//        let timeSlot = Date().currentTimeSlot
//        let savedPhotos = photos.enumerated().map { index, photo in
//            SavedPhoto(
//                frontImage: photo.front,
//                backImage: photo.back,
//                timeSlot: index < 3 ? TimeSlot.allCases[min(index, 2)] : (index == 3 ? .bonus1 : .bonus2),
//                capturedAt: Date()
//            )
//        }
//
//        if let todayIndex = dailyAlbums.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
//            dailyAlbums[todayIndex].photos.append(contentsOf: savedPhotos)
//        } else {
//            let newAlbum = DailyAlbum(date: Date(), photos: savedPhotos)
//            dailyAlbums.insert(newAlbum, at: 0)
//        }
//    }
}
