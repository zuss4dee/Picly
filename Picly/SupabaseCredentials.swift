import Foundation
import Supabase

enum SupabaseCredentials {
  static let url = URL(string: "https://ngvluxgxvbnxpnsfcedf.supabase.co")!
  static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ndmx1eGd4dmJueHBuc2ZjZWRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4OTc4NDIsImV4cCI6MjA3MjQ3Mzg0Mn0.BRl5jAY07BGX2PZgg8ouWUYWlnjkGNx2LJZThpu7hGs"
}

// Shared Supabase client (singleton)
let supabase = SupabaseClient(
    supabaseURL: SupabaseCredentials.url,
    supabaseKey: SupabaseCredentials.anonKey
)
