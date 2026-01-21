import SwiftUI

struct UpcomingView: View {
    @EnvironmentObject var upcomingManager: UpcomingManager
    @State private var isShowingAddSheet = false
    @State private var itemToEdit: UpcomingItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upcoming")
                        .font(.system(size: 32, weight: .bold))
                    Text("Your unified schedule for the coming weeks")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                
                Button(action: { isShowingAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Theme.accentBlue.opacity(0.8))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
            .padding(.bottom, 24)
            
            ScrollView {
                if upcomingManager.items.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                        Text("No upcoming items")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.textSecondary)
                        Button("Add Item") {
                            isShowingAddSheet = true
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.accentBlue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 12) {
                        // Filter out items that have been cleared via Alerts
                        // Do NOT filter out past items based on time, as they must remain visible until dismissed/cleared
                        // (UpcomingManager handles the hard 15m expiration)
                        let displayItems = upcomingManager.items.filter { item in
                            !upcomingManager.clearedAlertIDs.contains(item.id)
                        }
                        
                        ForEach(displayItems) { item in
                            UpcomingItemRow(
                                item: item,
                                onEdit: { itemToEdit = item },
                                onDelete: { upcomingManager.deleteItem(id: item.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .onAppear {
                upcomingManager.refresh()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .sheet(isPresented: $isShowingAddSheet) {
            AddUpcomingItemSheet()
        }
        .sheet(item: $itemToEdit) { item in
            AddUpcomingItemSheet(itemToEdit: item)
        }
    }
}

struct UpcomingItemRow: View {
    let item: UpcomingItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon (Keep strict 44x44 size)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.category.color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: item.category.icon)
                    .foregroundColor(item.category.color)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Top Row: Title + Urgent Badge + Type Badge
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                    
                    if item.isUrgent {
                        Text("URGENT")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Text(item.category.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.05))
                        .foregroundColor(Theme.textSecondary)
                        .cornerRadius(6)
                }
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary.opacity(0.8))
                        .lineLimit(1)
                }
                
                // Bottom Row: Date (Left) + Actions (Right)
                HStack {
                    Text(formatDate(item.dueDate, includeTime: item.includeTime))
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                    
                    Spacer()
                    
                    // Hover Actions
                    if isHovering {
                        HStack(spacing: 8) {
                            Button(action: onEdit) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(item.isUrgent ? Color.red.opacity(0.3) : isHovering ? Color.white.opacity(0.1) : Color.white.opacity(0.05), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
    
    func formatDate(_ date: Date, includeTime: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = includeTime ? .short : .none
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }
}

struct UpcomingView_Previews: PreviewProvider {
    static var previews: some View {
        UpcomingView()
    }
}
