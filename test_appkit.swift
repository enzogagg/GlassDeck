import AppKit

if let app = NSWorkspace.shared.frontmostApplication?.localizedName {
    print("Active app:", app)
} else {
    print("Could not get active app")
}
