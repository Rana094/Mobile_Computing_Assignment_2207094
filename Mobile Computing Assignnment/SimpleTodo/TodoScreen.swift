import FirebaseFirestore
import SwiftUI

private struct Todo: Identifiable {
    let id: String
    let title: String
}

struct TodoScreen: View {
    let userID: String
    let signOut: () throws -> Void

    @State private var todos: [Todo] = []
    @State private var listener: ListenerRegistration?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var actionError: String?
    @State private var draft = ""

    init(userID: String, signOut: @escaping () throws -> Void) {
        self.userID = userID
        self.signOut = signOut
    }

    private var collection: CollectionReference {
        Firestore.firestore().collection("users").document(userID).collection("todos")
    }

    var body: some View {
        TodoView(
            todos: todos,
            isLoading: isLoading,
            loadError: loadError,
            actionError: actionError,
            draft: $draft,
            add: add,
            delete: delete,
            retry: observeTodos,
            logOut: logOut
        )
        .onAppear(perform: observeTodos)
        .onDisappear {
            listener?.remove()
            listener = nil
        }
    }

    private func observeTodos() {
        listener?.remove()
        isLoading = true
        loadError = nil

        listener = collection.order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error {
                        loadError = error.localizedDescription
                    } else if let snapshot {
                        todos = snapshot.documents.compactMap { document in
                            guard let title = document.data()["title"] as? String else { return nil }
                            return Todo(id: document.documentID, title: title)
                        }
                    }
                }
            }
    }

    private func add() {
        let title = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        draft = ""
        actionError = nil
        collection.addDocument(data: [
            "title": title,
            "createdAt": FieldValue.serverTimestamp()
        ]) { error in
            DispatchQueue.main.async {
                guard let error else { return }
                if draft.isEmpty { draft = title }
                actionError = "Could not add the task. \(error.localizedDescription)"
            }
        }
    }

    private func delete(_ todo: Todo) {
        actionError = nil
        collection.document(todo.id).delete { error in
            DispatchQueue.main.async {
                if let error {
                    actionError = "Could not delete the task. \(error.localizedDescription)"
                }
            }
        }
    }

    private func logOut() {
        do {
            try signOut()
        } catch {
            actionError = "Could not log out. \(error.localizedDescription)"
        }
    }
}

private struct TodoView: View {
    let todos: [Todo]
    let isLoading: Bool
    let loadError: String?
    let actionError: String?
    @Binding var draft: String
    let add: () -> Void
    let delete: (Todo) -> Void
    let retry: () -> Void
    let logOut: () -> Void

    private var canAdd: Bool {
        !isLoading && loadError == nil && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
                .navigationTitle("My To-Dos")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Log Out", action: logOut)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    composer
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Loading tasks…")
        } else if let loadError {
            ContentUnavailableView {
                Label("Couldn’t Load Tasks", systemImage: "exclamationmark.circle")
            } description: {
                Text(loadError)
            } actions: {
                Button("Try Again", action: retry)
                    .buttonStyle(.bordered)
            }
        } else if todos.isEmpty {
            ContentUnavailableView(
                "No Tasks Yet",
                systemImage: "list.bullet",
                description: Text("Add your first task below.")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(todos) { todo in
                        HStack(spacing: 12) {
                            Text(todo.title)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button(role: .destructive) { delete(todo) } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("Delete \(todo.title)"))
                        }
                        .padding(.leading, 16)
                        .padding(.trailing, 6)
                        .padding(.vertical, 6)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let actionError {
                Text(actionError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 10) {
                TextField("Write a task…", text: $draft)
                    .submitLabel(.done)
                    .onSubmit {
                        if canAdd { add() }
                    }
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                Button("Add", action: add)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canAdd)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.background)
        .overlay(alignment: .top) { Divider() }
    }
}

#Preview("To-Do List") {
    @Previewable @State var todos = [
        Todo(id: "1", title: "Finish mobile computing assignment"),
        Todo(id: "2", title: "Review class notes")
    ]
    @Previewable @State var draft = ""

    TodoView(
        todos: todos,
        isLoading: false,
        loadError: nil,
        actionError: nil,
        draft: $draft,
        add: {
            let title = draft.trimmingCharacters(in: .whitespacesAndNewlines)
            todos.insert(Todo(id: UUID().uuidString, title: title), at: 0)
            draft = ""
        },
        delete: { todo in todos.removeAll { $0.id == todo.id } },
        retry: {},
        logOut: {}
    )
    .tint(.indigo)
}
