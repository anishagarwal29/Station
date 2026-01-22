import SwiftUI

struct AddResourceSheet: View {
    @ObservedObject var manager: ResourceManager
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var urlString = ""
    @State private var selectedIcon = "link"
    @State private var selectedTags: Set<String> = []
    
    let icons = ["link", "book", "graduationcap", "folder", "doc.text", "globe", "flask", "desktopcomputer"]
    let availableTags = ["Math", "Science", "History", "English", "CS", "General", "Exams", "Reference"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Resource")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button("Cancel") { isPresented = false }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding()
            .background(Theme.cardBackground)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Title & URL
                    VStack(alignment: .leading, spacing: 16) {
                        InputField(title: "Title", placeholder: "e.g. Textbook PDF", text: $title)
                        InputField(title: "URL", placeholder: "https://...", text: $urlString)
                    }
                    
                    // Icon Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                IconOption(icon: icon, isSelected: selectedIcon == icon) {
                                    selectedIcon = icon
                                }
                            }
                        }
                    }
                    
                    // Tags
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(availableTags, id: \.self) { tag in
                                TagToggle(tag: tag, isSelected: selectedTags.contains(tag)) {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
            
            // Footer
            HStack {
                Button(action: {
                    manager.addItem(title: title, urlString: urlString, tags: Array(selectedTags), iconName: selectedIcon)
                    isPresented = false
                }) {
                    Text("Add Resource")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.accentBlue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(title.isEmpty || urlString.isEmpty)
                .opacity(title.isEmpty || urlString.isEmpty ? 0.5 : 1.0)
            }
            .padding(24)
            .background(Theme.cardBackground)
        }
        .frame(width: 400, height: 600)
        .background(Theme.background)
    }
}

// Helpers
struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

struct IconOption: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(isSelected ? Theme.accentBlue : Color.white.opacity(0.05))
                .foregroundColor(isSelected ? .white : Theme.textSecondary)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct TagToggle: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.accentBlue.opacity(0.2) : Color.white.opacity(0.05))
                .foregroundColor(isSelected ? Theme.accentBlue : Theme.textSecondary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Theme.accentBlue : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
