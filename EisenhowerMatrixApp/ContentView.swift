//
//  ContentView.swift
//  EisenhowerMatrixApp
//
//  Created by user280681 on 8/2/25.
//

import SwiftUI

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var priority: Priority
    var isCompleted: Bool = false
    var dateCreated: Date = Date()
    
    init(title: String, description: String, priority: Priority) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.priority = priority
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.priority = try container.decode(Priority.self, forKey: .priority)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.dateCreated = try container.decode(Date.self, forKey: .dateCreated)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(priority, forKey: .priority)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(dateCreated, forKey: .dateCreated)
    }
    
    // Custom coding keys to handle UUID
    private enum CodingKeys: String, CodingKey {
        case id, title, description, priority, isCompleted, dateCreated
    }
    
    enum Priority: String, CaseIterable, Codable {
        case urgentImportant = "Urgent & Important"
        case urgentNotImportant = "Urgent & Not Important"
        case notUrgentImportant = "Not Urgent & Important"
        case notUrgentNotImportant = "Not Urgent & Not Important"
        
        var color: Color {
            switch self {
            case .urgentImportant: return .red
            case .urgentNotImportant: return .orange
            case .notUrgentImportant: return .blue
            case .notUrgentNotImportant: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .urgentImportant:
                return "exclamationmark.triangle.fill"
            case .urgentNotImportant:
                return "⏰"
            case .notUrgentImportant:
                return "star.fill"
            case .notUrgentNotImportant:
                return "🗑️"
            }
        }
    }
}

// MARK: - Data Manager
class TaskManager: ObservableObject {
    @Published var tasks: [TaskItem] = []
    
    init() {
        loadSampleData()
    }
    
    func addTask(title: String, description: String, priority: TaskItem.Priority) {
        let newTask = TaskItem(
            title: title,
            description: description,
            priority: priority
        )
        tasks.append(newTask)
    }
    
    func loadSampleData() {
        tasks = [
            // Urgent & Important - 7 tasks (will show 5 + "More...")
            TaskItem(title: "Deadline project", description: "Complete urgent project", priority: .urgentImportant),
            TaskItem(title: "Team meeting", description: "Prepare for meeting", priority: .urgentImportant),
            TaskItem(title: "Client presentation", description: "Prepare slides", priority: .urgentImportant),
            TaskItem(title: "Budget review", description: "Review quarterly budget", priority: .urgentImportant),
            TaskItem(title: "Emergency call", description: "Handle urgent client call", priority: .urgentImportant),
            TaskItem(title: "Project deadline", description: "Finalize project deliverables", priority: .urgentImportant),
            TaskItem(title: "Critical bug fix", description: "Fix production bug", priority: .urgentImportant),
            
            // Urgent & Not Important - 3 tasks (will show all 3)
            TaskItem(title: "Email responses", description: "Reply to emails", priority: .urgentNotImportant),
            TaskItem(title: "Phone calls", description: "Return calls", priority: .urgentNotImportant),
            TaskItem(title: "Meeting prep", description: "Prepare for team meeting", priority: .urgentNotImportant),
            
            // Not Urgent & Important - 4 tasks (will show all 4)
            TaskItem(title: "Strategic planning", description: "Plan goals", priority: .notUrgentImportant),
            TaskItem(title: "Skill development", description: "Learn technology", priority: .notUrgentImportant),
            TaskItem(title: "Network building", description: "Connect with colleagues", priority: .notUrgentImportant),
            TaskItem(title: "Process improvement", description: "Optimize workflows", priority: .notUrgentImportant),
            
            // Not Urgent & Not Important - 2 tasks (will show all 2)
            TaskItem(title: "Social media", description: "Check updates", priority: .notUrgentNotImportant),
            TaskItem(title: "Some interruptions", description: "Handle distractions", priority: .notUrgentNotImportant)
        ]
    }
    
    func toggleTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func tasksForPriority(_ priority: TaskItem.Priority) -> [TaskItem] {
        return tasks.filter { $0.priority == priority }
    }
    
    func moveTask(_ task: TaskItem, to newPriority: TaskItem.Priority) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].priority = newPriority
        }
    }
}

// MARK: - Drop View Delegate
struct DropViewDelegate: DropDelegate {
    let taskManager: TaskManager
    let targetPriority: TaskItem.Priority
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        itemProvider.loadObject(ofClass: NSString.self) { string, _ in
            if let taskIdString = string as? String,
               let taskId = UUID(uuidString: taskIdString) {
                DispatchQueue.main.async {
                    if let task = self.taskManager.tasks.first(where: { $0.id == taskId }) {
                        self.taskManager.moveTask(task, to: self.targetPriority)
                    }
                }
            }
        }
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Optional: Add visual feedback when dragging over
    }
    
    func dropExited(info: DropInfo) {
        // Optional: Remove visual feedback when dragging away
    }
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var selectedPriority: TaskItem.Priority?
    @State private var selectedPriorityForAdd: TaskItem.Priority?
    @State private var showingDetail = false
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Eisenhower Matrix")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding()
                
                // Matrix Grid
                VStack(spacing: 0) {
                    // Top section: Urgent quadrants
                    HStack(spacing: 12) {
                        matrixQuadrant(priority: .urgentImportant, color: .red)
                        matrixQuadrant(priority: .urgentNotImportant, color: .orange)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Center section with proper spacing
                    Spacer()
                        .frame(height: 120)
                    
                    // Bottom section: Not Urgent quadrants (truly centered)
                    HStack {
                        Spacer()
                        HStack(spacing: 12) {
                            matrixQuadrant(priority: .notUrgentImportant, color: .blue)
                            matrixQuadrant(priority: .notUrgentNotImportant, color: .gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Bottom spacing
                    Spacer()
                        .frame(height: 120)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskManager: taskManager, priority: selectedPriorityForAdd ?? .urgentImportant)
        }
        .sheet(isPresented: $showingDetail) {
            if let priority = selectedPriority {
                PriorityDetailView(taskManager: taskManager, priority: priority)
            }
        }
    }
    
    private func matrixQuadrant(priority: TaskItem.Priority, color: Color) -> some View {
        let tasks = taskManager.tasksForPriority(priority)
        
        return VStack(spacing: 8) {
            HStack {
                Image(systemName: priority.icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(priority.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(tasks.prefix(5)) { task in
                    HStack {
                        Button(action: {
                            taskManager.toggleTask(task)
                        }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : color)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .strikethrough(task.isCompleted)
                            
                            Text(task.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            taskManager.deleteTask(task)
                        }) {
                            Text("🗑️")
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                    .onDrag {
                        NSItemProvider(object: task.id.uuidString as NSString)
                    }
                }
                
                if tasks.count > 5 {
                    Text("More...")
                        .font(.caption)
                        .foregroundColor(color)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // Add button
            Button(action: {
                selectedPriorityForAdd = priority
                showingAddTask = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(color)
                        .font(.caption)
                    Text("Add Task")
                        .font(.caption)
                        .foregroundColor(color)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding()
        .frame(width: 180, height: 220)
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color, lineWidth: 1)
        )
        .onTapGesture {
            selectedPriority = priority
            showingDetail = true
        }
        .onDrop(of: [.text], delegate: DropViewDelegate(taskManager: taskManager, targetPriority: priority))
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    let priority: TaskItem.Priority
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Priority")) {
                    HStack {
                        Image(systemName: priority.icon)
                            .foregroundColor(priority.color)
                        Text(priority.rawValue)
                            .foregroundColor(priority.color)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        taskManager.addTask(title: title, description: description, priority: priority)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Priority Detail View
struct PriorityDetailView: View {
    @ObservedObject var taskManager: TaskManager
    let priority: TaskItem.Priority
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: priority.icon)
                            .font(.title)
                            .foregroundColor(priority.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(priority.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(getSubtitle(for: priority))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(taskManager.tasksForPriority(priority).count) tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(taskManager.tasksForPriority(priority).filter { $0.isCompleted }.count) completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(priority.color.opacity(0.1))
                
                // Task List
                List {
                    ForEach(taskManager.tasksForPriority(priority)) { task in
                        TaskRowView(task: task, taskManager: taskManager)
                    }
                    .onDelete(perform: deleteTasks)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(priority.rawValue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Task") {
                        showingAddTask = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskManager: taskManager, priority: priority)
        }
    }
    
    private func getSubtitle(for priority: TaskItem.Priority) -> String {
        switch priority {
        case .urgentImportant:
            return "Do First - These require immediate attention"
        case .urgentNotImportant:
            return "Delegate - These can be delegated to others"
        case .notUrgentImportant:
            return "Schedule - Plan these for later"
        case .notUrgentNotImportant:
            return "Eliminate - Consider removing these tasks"
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        let tasksToDelete = taskManager.tasksForPriority(priority)
        for index in offsets {
            taskManager.deleteTask(tasksToDelete[index])
        }
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: TaskItem
    @ObservedObject var taskManager: TaskManager
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { taskManager.toggleTask(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .strikethrough(task.isCompleted)
            }
            
            Spacer()
            
            Text(task.dateCreated, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

extension TaskItem.Priority: Identifiable {
    var id: String { rawValue }
}

#Preview {
    ContentView()
}
