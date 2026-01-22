/*
 Station > Views > Dashboard > QuickNotesBlock.swift
 ---------------------------------------------------
 PURPOSE:
 A simple "Scratchpad" on the dashboard for fleeting thoughts.
 
 ARCHITECTURE:
 - Uses a localized "Mini Manager" pattern (QuickNotesManager) inside the file since this data isn't needed globally.
 - Shows how to build a list with a "Card" style row (QuickNoteRow).
 */

import SwiftUI
import Combine

// MODEL: Simple struct for a single note
struct QuickNote: Identifiable, Codable {
    let id: UUID
    var content: String
    var lastUpdated: Date
    
    init(id: UUID = UUID(), content: String, lastUpdated: Date = Date()) {
        self.id = id
        self.content = content
        self.lastUpdated = lastUpdated
    }
}

// MANAGER: Handles adding/deleting notes locally for this view.
// In a larger app, this might be moved to a separate file, but for a "Widget", keeping it here is fine.
class QuickNotesManager: ObservableObject {
    @Published var notes: [QuickNote] = []
    
    init() {
        // Optional: Load some mock data or persistence here if needed
        // For now, simple in-memory or mock for dashboard
    }
    
    func addNote(_ content: String) {
        let newNote = QuickNote(content: content)
        notes.insert(newNote, at: 0) // Add to top
    }
    
    func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
    }
}

struct QuickNotesBlock: View {
    // @StateObject: Owns the tech stack for this widget
    @StateObject private var quickNotesManager = QuickNotesManager()
    
    // UI State
    @State private var isShowingAddNote = false
    @State private var newNoteText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Quick Notes")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Button(action: {
                    newNoteText = ""
                    isShowingAddNote = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // List of Notes
            VStack(alignment: .leading, spacing: 12) {
                if quickNotesManager.notes.isEmpty {
                    // Empty State: Encourages user to add something
                    HStack {
                        Text("No notes. Click + to add one.")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                    }
                    .padding(Theme.padding)
                    .background(Theme.cardBackground)
                    .cornerRadius(Theme.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                } else {
                    ForEach(quickNotesManager.notes) { note in
                        QuickNoteRow(
                            note: note,
                            onComplete: { quickNotesManager.deleteNote(id: note.id) }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingAddNote) {
            // Simple Sheet for entering text
            VStack(alignment: .leading, spacing: 16) {
                Text("New Quick Note")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                
                TextEditor(text: $newNoteText)
                    .scrollContentBackground(.hidden)
                    .frame(height: 150)
                    .padding(8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                HStack {
                    Button("Cancel") {
                        isShowingAddNote = false
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.textSecondary)
                    
                    Spacer()
                    
                    Button(action: {
                        if !newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            quickNotesManager.addNote(newNoteText)
                        }
                        isShowingAddNote = false
                    }) {
                        Text("Add Note")
                            // ... Styling for Add Button ...
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "3494FF"), Color(hex: "0A74F5")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .frame(width: 400)
            .background(
                LinearGradient(
                    colors: [Theme.background, Theme.cardBackground.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

struct QuickNoteRow: View {
    let note: QuickNote
    let onComplete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Note Content
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "pencil.and.outline")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))
                    .padding(.top, 4)
                
                Text(note.content)
                    .font(.system(size: 14, weight: .medium))
                    .italic()
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.trailing, 32)
            .padding(16)
            
            Divider()
                .frame(height: 0.5)
                .background(Color.white.opacity(0.04))
            
            // Footer: Timestamp
            HStack {
                Text(timeString(for: note.lastUpdated))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary.opacity(0.6))
                
                Spacer()
            }
            .padding(12)
            .background(Color.white.opacity(0.02))
        }
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        // Checkmark Overlay (Visible on Hover)
        .overlay(
            Group {
                if isHovering {
                    Button(action: onComplete) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Mark as completed")
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                }
            },
            alignment: .topTrailing
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
    
    private func timeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Updated " + formatter.localizedString(for: date, relativeTo: Date()).replacingOccurrences(of: ".", with: "")
    }
}
