//
//  ContentView.swift
//  staybusy
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar.day.timeline.left")
                }

            MapTabView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            TripTabView()
                .tabItem {
                    Label("Trip", systemImage: "suitcase.fill")
                }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .toolbarBackground(Theme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Block.self, inMemory: true)
}
