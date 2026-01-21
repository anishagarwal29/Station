import SwiftUI

struct QuickNotesBlock: View {
    @StateObject private var notesManager = NotesManager()
    @State private var isShowingAddNote = false
    @State private var newNoteText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            
            VStack(alignment: .leading, spacing: 0) {
                if notesManager.notes.isEmpty {
                    Text("No notes. Click + to add one.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .padding(Theme.padding)
                } else {
                    ForEach(notesManager.notes) { note in
                        QuickNoteRow(
                            note: note,
                            onComplete: { notesManager.completeNote(id: note.id) }
                        )
                        
                        if note.id != notesManager.notes.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.1))
                        }
                    }
                }
            }
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .sheet(isPresented: $isShowingAddNote) {
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
                            notesManager.addNote(newNoteText)
                        }
                        isShowingAddNote = false
                    }) {
                        Text("Add Note")
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
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if isHovering {
                    Button(action: onComplete) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                            .padding(6)
                            .background(Color.white.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Mark as completed")
                    .padding(.top, -2)
                }
            }
            .padding(.bottom, 4)
            
            Divider()
                .frame(height: 0.5)
                .background(Color.white.opacity(0.04))
            
            HStack {
                Text(timeString(for: note.lastUpdated))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary.opacity(0.6))
                
                Spacer()
            }
            .padding(.top, 12)
        }
        .padding(16)
        .background(isHovering ? Color.white.opacity(0.03) : Color.clear)
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
