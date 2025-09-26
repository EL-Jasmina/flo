//
//  ContentView.swift
//  flo
//
//  Created by rizaldy on 01/06/24.
//

import NukeUI
import PulseUI
import SwiftUI

struct ContentView: View {
    @AppStorage(UserDefaultsKeys.enableDebug) private var enableDebug = false

    @State private var isPlayerExpanded: Bool = false
    @State private var tabViewID = UUID()

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var albumViewModel = AlbumViewModel()
    @StateObject private var floooViewModel = FloooViewModel()
    @StateObject private var downloadViewModel = DownloadViewModel()

    @State private var floatingPlayerOffsetX: CGFloat = .zero
    @State private var isSwipping = false

    private var swipeThreshold: CGFloat = 150.0

    var body: some View {
        if #available(iOS 26, *) {
            TabView {
                Tab("Home", systemImage: "house") {
                    HomeView(viewModel: authViewModel)
                        .environmentObject(floooViewModel)
                }
                if authViewModel.isLoggedIn {
                    Tab("Library", systemImage: "square.grid.2x2") {
                        LibraryView(viewModel: albumViewModel)
                            .environmentObject(
                                playerViewModel
                            )
                            .environmentObject(downloadViewModel)
                            .onAppear {
                                albumViewModel.fetchAlbums()
                            }
                    }
                }
                Tab("Downloads", systemImage: "arrow.down.circle") {
                    DownloadsView(viewModel: albumViewModel)
                        .environmentObject(playerViewModel)
                        .environmentObject(
                            downloadViewModel
                        )
                        .onAppear {
                            albumViewModel.fetchDownloadedAlbums()
                        }
                        .badge(downloadViewModel.getRemainingDownloadItems())
                }
                Tab("Preferences", systemImage: "gear") {
                    PreferencesView(authViewModel: authViewModel)
                        .environmentObject(playerViewModel)
                        .environmentObject(
                            floooViewModel
                        )
                }
                if UserDefaultsManager.enableDebug {

                    Tab("Debug", systemImage: "terminal") {
                        ConsoleView()
                    }
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .tabViewBottomAccessory {
                if playerViewModel.hasNowPlaying() {
                    HStack {
                        if let image = UIImage(
                            contentsOfFile: playerViewModel.getAlbumCoverArt()
                        ) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    )
                                ).padding(.leading)
                        } else {
                            LazyImage(
                                url: URL(
                                    string: playerViewModel.getAlbumCoverArt()
                                )
                            ) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 30)
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 5,
                                                style: .continuous
                                            )
                                        )
                                        .padding(.leading)
                                } else {
                                    Color.gray.opacity(0.3).frame(
                                        width: 30,
                                        height: 30
                                    )
                                    .clipShape(
                                        RoundedRectangle(
                                            cornerRadius: 5,
                                            style: .continuous
                                        )
                                    )
                                    .padding(.leading)
                                }
                            }
                        }

                        VStack(alignment: .leading) {
                            Text(playerViewModel.nowPlaying.songName ?? "")
                                .customFont(.headline)
                                .lineLimit(1)
                            Text(playerViewModel.nowPlaying.artistName ?? "")
                                .customFont(.subheadline)
                                .lineLimit(1)
                        }
                        Spacer()
                        if playerViewModel.isMediaLoading {
                            ProgressView().progressViewStyle(
                                CircularProgressViewStyle(tint: .white)
                            ).padding()
                        } else {
                            Button {
                                playerViewModel.isPlaying
                                    ? playerViewModel.pause()
                                    : playerViewModel.play()
                            } label: {
                                Image(
                                    systemName: playerViewModel.isPlaying
                                        ? "pause.fill" : "play.fill"
                                )
                                .padding()
                                .font(.system(size: 20))
                                .disabled(playerViewModel.isMediaLoading)
                            }.opacity(playerViewModel.isMediaFailed ? 0 : 1)
                        }

                    }
                }
            }
            .sheet(
                isPresented: $isPlayerExpanded,
                onDismiss: {
                    isPlayerExpanded = false
                }
            ) {
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 15,
                                style: .continuous
                            )
                        )
                    PlayerView(isExpanded: $isPlayerExpanded, viewModel: PlayerViewModel())
                }
            }
            .id(tabViewID)
            .onChange(of: enableDebug) { _ in
                tabViewID = UUID()
            }
        } else {
            ZStack {
                TabView {
                    HomeView(viewModel: authViewModel).tabItem {
                        Label("Home", systemImage: "house")
                    }.environmentObject(floooViewModel)

                    if authViewModel.isLoggedIn {
                        LibraryView(viewModel: albumViewModel).tabItem {
                            Label("Library", systemImage: "square.grid.2x2")
                        }.environmentObject(playerViewModel).environmentObject(
                            downloadViewModel
                        )
                        .onAppear {
                            albumViewModel.fetchAlbums()
                        }
                    }

                    DownloadsView(viewModel: albumViewModel).tabItem {
                        Label("Downloads", systemImage: "arrow.down.circle")
                    }.environmentObject(playerViewModel).environmentObject(
                        downloadViewModel
                    ).onAppear {
                        albumViewModel.fetchDownloadedAlbums()
                    }.badge(downloadViewModel.getRemainingDownloadItems())

                    PreferencesView(authViewModel: authViewModel).tabItem {
                        Label("Preferences", systemImage: "gear")
                    }.environmentObject(playerViewModel).environmentObject(
                        floooViewModel
                    )

                    if UserDefaultsManager.enableDebug {
                        ConsoleView().tabItem {
                            Label("Debug", systemImage: "terminal")
                        }
                    }
                }
                .id(tabViewID)
                .onChange(of: enableDebug) { _ in
                    tabViewID = UUID()
                }

                ZStack {
                    if playerViewModel.hasNowPlaying()
                        && !playerViewModel.shouldHidePlayer
                    {
                        PlayerView(
                            isExpanded: $isPlayerExpanded,
                            viewModel: playerViewModel
                        )
                        .offset(
                            y: isPlayerExpanded
                                ? 0 : UIScreen.main.bounds.height
                        )
                        .animation(
                            .spring(duration: 0.2),
                            value: isPlayerExpanded
                        )
                    }
                }

                VStack {
                    Spacer()

                    if playerViewModel.hasNowPlaying()
                        && !playerViewModel.shouldHidePlayer
                    {
                        FloatingPlayerView(viewModel: playerViewModel)
                            .padding(.bottom, 50)
                            .opacity(playerViewModel.hasNowPlaying() ? 1 : 0)
                            .offset(
                                x: self.floatingPlayerOffsetX,
                                y: isPlayerExpanded
                                    ? UIScreen.main.bounds.height : 0
                            )
                            .animation(
                                .spring(duration: 0.2),
                                value: isPlayerExpanded
                            )
                            .onTapGesture {
                                self.isPlayerExpanded = true
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        // only care with swipe left :))
                                        if value.translation.width < .zero {
                                            floatingPlayerOffsetX =
                                                value.translation.width
                                        }

                                        // debounce thing
                                        if abs(floatingPlayerOffsetX)
                                            > swipeThreshold && !isSwipping
                                        {
                                            isSwipping = true
                                        }
                                    }
                                    .onEnded { value in
                                        if abs(floatingPlayerOffsetX)
                                            > swipeThreshold && isSwipping
                                        {
                                            playerViewModel
                                                .destroyPlayerAndQueue()
                                        }

                                        self.floatingPlayerOffsetX = .zero
                                        self.isSwipping = false
                                    }
                            )
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
