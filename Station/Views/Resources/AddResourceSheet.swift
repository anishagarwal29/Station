/*
 Station > Views > Resources > AddResourceSheet.swift
 ----------------------------------------------------
 PURPOSE:
 A modal form (sheet) that allows users to create a new ResourceItem.
 
 SWIFTUI PATTERNS:
 - @Binding: This view doesn't "own" the `isPresented` state; the parent (ResourcesView) does.
   We just have a reference (binding) to it so we can set it to `false` to close ourselves.
 - Form Validation: The "Add" button is disabled until valid input is detected.
 */

import SwiftUI

struct AddResourceSheet: View {
    // Reference to the shared brain. We use this to actually add the item.
    @ObservedObject var manager: ResourceManager
    
    // Optional Item to Edit
    var itemToEdit: ResourceItem? = nil
    
    // Binding to the 'show' toggle in the parent view.
    @Binding var isPresented: Bool
    
    // Temporary State for the Form
    @State private var title: String
    @State private var urlString: String
    @State private var selectedIcon: String
    @State private var selectedTags: Set<String>
    @State private var isPinned: Bool
    
    init(manager: ResourceManager, isPresented: Binding<Bool>, itemToEdit: ResourceItem? = nil) {
        self.manager = manager
        self._isPresented = isPresented
        self.itemToEdit = itemToEdit
        
        // Initialize State based on whether we are editing or creating
        if let item = itemToEdit {
            _title = State(initialValue: item.title)
            _urlString = State(initialValue: item.urlString)
            _selectedIcon = State(initialValue: item.iconName)
            _selectedTags = State(initialValue: Set(item.tags))
            _isPinned = State(initialValue: item.isPinned)
        } else {
            _title = State(initialValue: "")
            _urlString = State(initialValue: "")
            _selectedIcon = State(initialValue: "link")
            _selectedTags = State(initialValue: [])
            _isPinned = State(initialValue: false)
        }
    }
    
    let icons = ["link", "book", "graduationcap", "folder", "doc.text", "globe", "flask", "desktopcomputer"]
    let availableTags = ["Math", "Science", "History", "English", "CS", "General", "Exams", "Reference"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(itemToEdit == nil ? "Add Resource" : "Edit Resource")
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
                    // Title & URL Inputs
                    VStack(alignment: .leading, spacing: 16) {
                        InputField(title: "Title", placeholder: "e.g. Textbook PDF", text: $title)
                        InputField(title: "URL", placeholder: "https://...", text: $urlString)
                        
                        Toggle(isOn: $isPinned) {
                            HStack(spacing: 8) {
                                Image(systemName: isPinned ? "pin.fill" : "pin")
                                    .foregroundColor(isPinned ? Theme.accentBlue : Theme.textSecondary)
                                Text("Pin to Dashboard")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.textPrimary)
                            }
                        }
                        .toggleStyle(.switch)
                        .padding(.top, 4)
                    }
                    
                    // ... (Icon Picker and Tags) ...
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
                        
                        // Adaptive Grid for tags (like a wrapping flow layout)
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
            
            // Footer Action
            HStack {
                Button(action: {
                    // ACTION: Commit Data
                    if let existingItem = itemToEdit {
                        // EDIT MODE
                        var updated = existingItem
                        updated.title = title
                        updated.urlString = urlString
                        updated.tags = Array(selectedTags)
                        updated.iconName = selectedIcon
                        updated.isPinned = isPinned
                        manager.updateItem(updated)
                    } else {
                        // CREATE MODE
                        manager.addItem(title: title, urlString: urlString, tags: Array(selectedTags), iconName: selectedIcon, isPinned: isPinned)
                    }
                    // 2. Close the sheet
                    isPresented = false
                }) {
                    Text(itemToEdit == nil ? "Add Resource" : "Save Changes")
                        .font(.system(size: 14, weight: .semibold))
                        // ... styling ...
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.accentBlue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                // LOGIC: Validation
                // Prevent adding empty items
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
