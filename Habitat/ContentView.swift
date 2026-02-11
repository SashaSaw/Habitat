//
//  ContentView.swift
//  Habitat
//
//  Created by Alexander Saw on 02/02/2026.
//

import SwiftUI
import SwiftData
import UIKit

/// Main app view with tab navigation
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    @State private var habitStore: HabitStore?

    init() {
        // Make tab bar fully transparent
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.clear
        tabBarAppearance.shadowColor = UIColor.clear
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Make navigation bar fully transparent
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = UIColor.clear
        navBarAppearance.shadowColor = UIColor.clear
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }

    var body: some View {
        Group {
            if let store = habitStore {
                if hasCompletedOnboarding {
                    TabView(selection: $selectedTab) {
                        TodayView(store: store)
                            .tabItem {
                                Label("Today", systemImage: "checkmark.circle")
                            }
                            .tag(0)

                        MyHabitsView(store: store)
                            .tabItem {
                                Label("My Habits", systemImage: "square.grid.2x2")
                            }
                            .tag(1)

                        MonthGridView(store: store)
                            .tabItem {
                                Label("Month", systemImage: "calendar")
                            }
                            .tag(2)

                        StatsView(store: store)
                            .tabItem {
                                Label("Stats", systemImage: "chart.bar")
                            }
                            .tag(3)
                    }
                    .tint(JournalTheme.Colors.inkBlue)
                    .onAppear {
                        // Refresh smart reminders on app launch with current habit state
                        store.refreshSmartReminders()
                    }
                } else {
                    OnboardingView(store: store, onComplete: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hasCompletedOnboarding = true
                        }
                    })
                }
            } else {
                ProgressView()
                    .onAppear {
                        habitStore = HabitStore(modelContext: modelContext)
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitGroup.self, DailyLog.self], inMemory: true)
}
