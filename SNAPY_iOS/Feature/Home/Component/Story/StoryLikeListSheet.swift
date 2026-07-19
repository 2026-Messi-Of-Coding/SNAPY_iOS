//
//  StoryLikeListSheet.swift
//  SNAPY_iOS
//
//  Separated from StoryDetailView.swift
//

import SwiftUI
import Kingfisher

struct StoryLikeListSheet: View {
    let likeUsers: [StoryLikeUserData]
    let onSelectUser: (StoryLikeUserData) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("좋아요")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textWhite)
                .padding(.top, 20)
                .padding(.bottom, 16)

            if likeUsers.isEmpty {
                Spacer()
                Text("아직 좋아요가 없습니다")
                    .font(.system(size: 15))
                    .foregroundColor(.customGray300)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(likeUsers) { user in
                            Button {
                                onSelectUser(user)
                            } label: {
                                HStack(spacing: 12) {
                                    if let url = user.profileImageUrl, let imgUrl = URL(string: url) {
                                        KFImage(imgUrl)
                                            .resizable()
                                            .placeholder { Image("Profile_img").resizable().scaledToFill() }
                                            .scaledToFill()
                                            .frame(width: 44, height: 44)
                                            .clipShape(Circle())
                                    } else {
                                        Image("Profile_img")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 44, height: 44)
                                            .clipShape(Circle())
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(user.username)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.textWhite)
                                        Text("@\(user.handle)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.customGray300)
                                    }

                                    Spacer()

                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                }
                                .contentShape(Rectangle())
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
