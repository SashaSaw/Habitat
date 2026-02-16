//
//  ContentView.swift
//  Sown
//
//  Created by Alexander Saw on 02/02/2026.
//

import SwiftUI
import SwiftData
import UIKit

/// Main app view with tab navigation
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab = 0
    @State private var habitStore: HabitStore?
    @State private var showingInterceptView = false

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

                        MonthGridView(store: store)
                            .tabItem {
                                Label("Month", systemImage: "calendar")
                            }
                            .tag(1)

                        JournalView(store: store)
                            .tabItem {
                                Label("Journal", systemImage: "book")
                            }
                            .tag(2)

                        StatsView(store: store)
                            .tabItem {
                                Label("Stats", systemImage: "chart.bar")
                            }
                            .tag(3)

                        SettingsView(store: store)
                            .tabItem {
                                Label("Settings", systemImage: "gearshape")
                            }
                            .tag(4)
                    }
                    .tint(JournalTheme.Colors.inkBlue)
                    .onAppear {
                        // Refresh smart reminders on app launch with current habit state
                        store.refreshSmartReminders()
                        // Check if launched from shield
                        checkAndShowIntercept()
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active {
                            // Check if returning from a shield tap
                            checkAndShowIntercept()
                        }
                    }
                    .onOpenURL { url in
                        // Handle sown://intercept deep link
                        if url.scheme == "sown" && url.host == "intercept" {
                            showingInterceptView = true
                        }
                    }
                    .fullScreenCover(isPresented: $showingInterceptView) {
                        InterceptView(
                            store: store,
                            blockedAppName: "App",
                            blockedAppEmoji: "📱",
                            blockedAppColor: .gray
                        )
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

    /// Check if the shield action sent us an intercept request via App Group
    private func checkAndShowIntercept() {
        guard !showingInterceptView else { return }

        let defaults = UserDefaults(suiteName: "group.com.incept5.SeedBed")
        if let requestTime = defaults?.double(forKey: "interceptRequested"), requestTime > 0 {
            // Only honour requests from the last 30 seconds (avoid stale flags)
            let age = Date().timeIntervalSince1970 - requestTime
            if age < 30 {
                // Clear the flag so it doesn't re-trigger
                defaults?.removeObject(forKey: "interceptRequested")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingInterceptView = true
                }
                return
            } else {
                // Stale flag — clean it up
                defaults?.removeObject(forKey: "interceptRequested")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Habit.self, HabitGroup.self, DailyLog.self, DayRecord.self, EndOfDayNote.self], inMemory: true)
}
