//
//  PiclyApp.swift
//  Picly
//
//  Created by Damilare Adeosun on 01/09/2025.
//

import SwiftUI
import SwiftData
import SuperwallKit
import Supabase

@main
struct PiclyApp: App {
    // Configure Superwall when the app launches
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Replace with your actual Superwall API key
        Superwall.configure(apiKey: "pk_30iDJaUHzpLM6z2_iIxpq")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
        .modelContainer(for: [Shoot.self, MediaAsset.self])
    }
}
