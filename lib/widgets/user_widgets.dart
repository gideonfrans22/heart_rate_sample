import 'package:flutter/material.dart';

/// Callback for when a user is selected
typedef OnUserSelected = void Function(Map<String, dynamic> user);

/// Callback for when a video/movie is selected
typedef OnVideoSelected = void Function(Map<String, dynamic> video);

/// A widget for searching and selecting users with optional create functionality
class UserSelectionCard extends StatelessWidget {
  final Map<String, dynamic>? selectedUser;
  final List<Map<String, dynamic>> searchResults;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final OnUserSelected onUserSelected;
  final VoidCallback? onClearSelection;
  final VoidCallback? onCreateNew;
  final String title;
  final bool showCreateButton;

  const UserSelectionCard({
    super.key,
    this.selectedUser,
    required this.searchResults,
    required this.searchController,
    required this.onSearchChanged,
    required this.onUserSelected,
    this.onClearSelection,
    this.onCreateNew,
    this.title = 'Select User',
    this.showCreateButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (selectedUser != null)
              _buildSelectedUserCard(context)
            else
              _buildUserSearchSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUserCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade400,
            child: Text(
              selectedUser!['name']?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedUser!['name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (selectedUser!['email'] != null)
                  Text(
                    selectedUser!['email'],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
          if (onClearSelection != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClearSelection,
              tooltip: 'Clear selection',
            ),
        ],
      ),
    );
  }

  Widget _buildUserSearchSection(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Search Users',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 8),
        if (searchResults.isNotEmpty)
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final user = searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade400,
                    child: Text(
                      user['name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user['name'] ?? 'Unknown'),
                  subtitle: Text(user['email'] ?? 'No email'),
                  onTap: () => onUserSelected(user),
                );
              },
            ),
          ),
        if (showCreateButton && onCreateNew != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onCreateNew,
            icon: const Icon(Icons.add),
            label: const Text('Create New User'),
          ),
        ],
      ],
    );
  }
}

/// A widget for searching and selecting videos/movies with optional create functionality
class VideoSelectionCard extends StatelessWidget {
  final Map<String, dynamic>? selectedVideo;
  final List<Map<String, dynamic>> searchResults;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final OnVideoSelected onVideoSelected;
  final VoidCallback? onClearSelection;
  final VoidCallback? onCreateNew;
  final String title;
  final bool showCreateButton;

  const VideoSelectionCard({
    super.key,
    this.selectedVideo,
    required this.searchResults,
    required this.searchController,
    required this.onSearchChanged,
    required this.onVideoSelected,
    this.onClearSelection,
    this.onCreateNew,
    this.title = 'Select Video',
    this.showCreateButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (selectedVideo != null)
              _buildSelectedVideoCard(context)
            else
              _buildVideoSearchSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedVideoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.shade400,
            child: const Icon(Icons.movie, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedVideo!['title'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (selectedVideo!['description'] != null)
                  Text(
                    selectedVideo!['description'],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (onClearSelection != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClearSelection,
              tooltip: 'Clear selection',
            ),
        ],
      ),
    );
  }

  Widget _buildVideoSearchSection(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Search Videos',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 8),
        if (searchResults.isNotEmpty)
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final video = searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade400,
                    child: const Icon(Icons.movie, color: Colors.white),
                  ),
                  title: Text(video['title'] ?? 'Unknown'),
                  subtitle: Text(
                    video['description'] ?? 'No description',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onVideoSelected(video),
                );
              },
            ),
          ),
        if (showCreateButton && onCreateNew != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onCreateNew,
            icon: const Icon(Icons.add),
            label: const Text('Create New Video'),
          ),
        ],
      ],
    );
  }
}

/// Simple user picker widget (for predict page)
class UserPickerCard extends StatelessWidget {
  final String? selectedUserId;
  final String? selectedUserName;
  final VoidCallback onSelectUser;
  final bool isRecording;

  const UserPickerCard({
    super.key,
    this.selectedUserId,
    this.selectedUserName,
    required this.onSelectUser,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedUserName ?? 'Not selected',
                    style: TextStyle(
                      color: selectedUserName != null
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: isRecording ? null : onSelectUser,
              icon: const Icon(Icons.person),
              label: Text(selectedUserId != null ? 'Change' : 'Select'),
            ),
          ],
        ),
      ),
    );
  }
}
