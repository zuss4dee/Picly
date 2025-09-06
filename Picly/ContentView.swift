//
//  ContentView.swift
//  Picly
//
//  Created by Damilare Adeosun on 01/09/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        if authViewModel.isAuthenticated {
            NavigationStack {
                TabView {
                    ShootsDashboardView(modelContext: modelContext)
                        .tabItem { Image(systemName: "folder"); Text("Projects") }
                    SettingsView()
                        .tabItem { Image(systemName: "gearshape"); Text("Settings") }
                }
                .tint(.blue)
            }
        } else {
            AuthView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .modelContainer(for: [Shoot.self, MediaAsset.self])
}
