/*
 Station > Views > Upcoming > AddUpcomingItemSheet.swift
 -------------------------------------------------------
 PURPOSE:
 A Modal Sheet used to Create OR Edit an Upcoming Task.
 
 ARCHITECTURE:
 - Uses `@Environment(\.presentationMode)` to close itself.
 - Uses a custom `init` to populate fields if editing an existing item.
 - Binds directly to local @State variables, then commits to `UpcomingManager` on Save.
 */

import SwiftUI

struct AddUpcomingItemSheet: View {
    // Allows us to programmatically close the sheet
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var upcomingManager: UpcomingManager
    
    // Form State
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var dueDate: Date = Date()
    @State private var includeTime: Bool = false
    @State private var category: UpcomingItem.UpcomingCategory = .homework
    @State private var isUrgent: Bool = false
    
    // If this is set, we are in "Edit Mode". If nil, "Create Mode".
    var itemToEdit: UpcomingItem?
    
    // Custom Init: Pre-fill state if we are editing
    init(itemToEdit: UpcomingItem? = nil) {
        self.itemToEdit = itemToEdit
        // We must Initialize State manually because "self.title = ..." doesn't work on @State inside init
        _title = State(initialValue: itemToEdit?.title ?? "")
        _description = State(initialValue: itemToEdit?.description ?? "")
        // Default time: Now + 1 Hour (if creating new)
        _dueDate = State(initialValue: itemToEdit?.dueDate ?? Date().addingTimeInterval(3600))
        _includeTime = State(initialValue: itemToEdit?.includeTime ?? false)
        _category = State(initialValue: itemToEdit?.category ?? .homework)
        _isUrgent = State(initialValue: itemToEdit?.isUrgent ?? false)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(itemToEdit == nil ? "Add Upcoming Item" : "Edit Upcoming Item")
                .font(.title3)
                .bold()
                .foregroundColor(Theme.textPrimary)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title Group
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TITLE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                        TextField("E.g. History Essay", text: $title)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(10)
                            .background(Theme.cardBackground)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Description Group
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DESCRIPTION (OPTIONAL)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                        TextEditor(text: $description)
                            .scrollContentBackground(.hidden)
                            .frame(height: 60)
                            .padding(8)
                            .background(Theme.cardBackground)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .font(.system(size: 13))
                    }
                    
                    // Date & Time Group
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DATE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                // Dynamic DatePicker: Hides time if 'includeTime' is false
                                DatePicker("", selection: $dueDate, displayedComponents: includeTime ? [.date, .hourAndMinute] : [.date])
                                    .labelsHidden()
                                
                                Toggle("Include Time", isOn: $includeTime)
                                    .toggleStyle(SwitchToggleStyle(tint: Theme.accentBlue))
                                    .controlSize(.mini)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        
                        // Type Group
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TYPE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                            Picker("Category", selection: $category) {
                                ForEach(UpcomingItem.UpcomingCategory.allCases) { category in
                                    Text(category.rawValue).tag(category)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    Toggle("Mark as Urgent", isOn: $isUrgent)
                        .toggleStyle(SwitchToggleStyle(tint: Color.red))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.top, 4)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Footer Actions
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.plain)
                .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                Button("Save") {
                    if let item = itemToEdit {
                        // UPDATE Logic
                        var updatedItem = item
                        updatedItem.title = title
                        updatedItem.description = description
                        updatedItem.dueDate = dueDate
                        updatedItem.category = category
                        updatedItem.isUrgent = isUrgent
                        updatedItem.includeTime = includeTime
                        upcomingManager.updateItem(updatedItem)
                    } else {
                        // CREATE Logic
                        upcomingManager.addItem(title: title, description: description, dueDate: dueDate, category: category, isUrgent: isUrgent, includeTime: includeTime)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction) // Enter key triggers save
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentBlue)
                .disabled(title.isEmpty) // Validation: Title required
            }
        }
        .padding(24)
        .frame(width: 420, height: 520)
        .background(Theme.background)
    }
}
