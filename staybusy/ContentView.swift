//
//  ContentView.swift
//  staybusy
//

import SwiftUI

enum TabSelection: Hashable {
    case today
    case map
    case trip
}

struct ContentView: View {
    @State private var selectedTab: TabSelection = .today
    @State private var todayDate: Date = Calendar.current.startOfDay(for: Date())

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedDate: $todayDate)
                .tabItem {
                    Label("Today", systemImage: "calendar.day.timeline.left")
                }
                .tag(TabSelection.today)

            MapTabView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(TabSelection.map)

            TripTabView(onSelectDay: { date in
                todayDate = Calendar.current.startOfDay(for: date)
                withAnimation { selectedTab = .today }
            })
            .tabItem {
                Label("Trip", systemImage: "suitcase.fill")
            }
            .tag(TabSelection.trip)
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
