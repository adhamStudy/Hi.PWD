import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ConfigurationScreen extends StatefulWidget {
  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final Map<String, CommandConfig> _commands = {};
  final TextEditingController _dadNameController = TextEditingController();
  final TextEditingController _dadNumberController = TextEditingController();
  final TextEditingController _momNameController = TextEditingController();
  final TextEditingController _momNumberController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load contact information
      _dadNameController.text = prefs.getString('contact_dad_name') ?? 'Dad';
      _dadNumberController.text = prefs.getString('contact_dad') ?? '';
      _momNameController.text = prefs.getString('contact_mom_name') ?? 'Mom';
      _momNumberController.text = prefs.getString('contact_mom') ?? '';

      // Load custom commands
      final commandsJson = prefs.getString('asl_commands') ?? '{}';
      final commandsMap = jsonDecode(commandsJson) as Map<String, dynamic>;

      setState(() {
        _commands.clear();
        commandsMap.forEach((key, value) {
          _commands[key] = CommandConfig.fromJson(value);
        });
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Failed to load configuration: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('contact_dad_name', _dadNameController.text.trim());
      await prefs.setString('contact_dad', _dadNumberController.text.trim());
      await prefs.setString('contact_mom_name', _momNameController.text.trim());
      await prefs.setString('contact_mom', _momNumberController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Contacts saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save contacts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commandsMap = _commands.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString('asl_commands', jsonEncode(commandsMap));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Commands saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save commands: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _dadNameController.dispose();
    _dadNumberController.dispose();
    _momNameController.dispose();
    _momNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Configure Commands'),
          backgroundColor: Colors.black87,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Configure Commands'),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: _saveContacts,
            icon: const Icon(Icons.save),
            tooltip: 'Save All Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency & Family Contacts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure who to call when using hand sign commands',
              style: TextStyle(color: Colors.white60, fontSize: 16),
            ),
            const SizedBox(height: 24),

            _buildContactSection(),

            const SizedBox(height: 40),

            const Text(
              'Default Commands',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'These commands are built-in and always available',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 16),

            _buildDefaultCommandsSection(),

            const SizedBox(height: 32),

            _buildCustomCommandsSection(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomCommandDialog,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add),
        label: const Text('Add Custom Command'),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Family Contacts',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dad Contact
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.man, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Father Contact',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dadNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Name (e.g., Dad, Papa, Father)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dadNumberController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.phone, color: Colors.white70),
                    hintText: '+1 234 567 8900',
                    hintStyle: const TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),

          // Mom Contact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.woman, color: Colors.pink, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Mother Contact',
                      style: TextStyle(
                        color: Colors.pink,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _momNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Name (e.g., Mom, Mama, Mother)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _momNumberController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.phone, color: Colors.white70),
                    hintText: '+1 234 567 8900',
                    hintStyle: const TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveContacts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.save),
              label: const Text(
                'Save Contacts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCommandsSection() {
    final defaultCommands = [
      {'sign': '00001 → 01111', 'action': 'Call ${_dadNameController.text.isNotEmpty ? _dadNameController.text : 'Dad'}', 'icon': Icons.call, 'color': Colors.blue},
      {'sign': '00001 → 01110', 'action': 'Call ${_momNameController.text.isNotEmpty ? _momNameController.text : 'Mom'}', 'icon': Icons.call, 'color': Colors.pink},
      {'sign': '00001 → 01000 → 01100', 'action': 'Call Police (911)', 'icon': Icons.local_police, 'color': Colors.red},
      {'sign': '01000 → 00111', 'action': 'Open Google', 'icon': Icons.search, 'color': Colors.orange},
      {'sign': '01000 → 01111', 'action': 'Open Google Assistant', 'icon': Icons.assistant, 'color': Colors.green},
      {'sign': '01000 → 00010 → 00001', 'action': 'Send Message', 'icon': Icons.message, 'color': Colors.purple},
      {'sign': '01100 → 00001 → 01000', 'action': 'Open Camera', 'icon': Icons.camera_alt, 'color': Colors.cyan},
      {'sign': '00010 → 01000 → 01110', 'action': 'Play Music', 'icon': Icons.music_note, 'color': Colors.deepPurple},
      {'sign': '00001 → 00010 → 01100', 'action': 'Take Screenshot', 'icon': Icons.screenshot, 'color': Colors.teal},
      {'sign': '01000 → 01100 → 00001', 'action': 'Open Calculator', 'icon': Icons.calculate, 'color': Colors.amber},
    ];

    return Column(
      children: defaultCommands.map((command) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: (command['color'] as Color).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(command['icon'] as IconData, color: command['color'] as Color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command['action'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    command['sign'] as String,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (command['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Built-in',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildCustomCommandsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Custom Commands',
              style: TextStyle(
                color: Colors.purple,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Create your own custom gesture commands',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        const SizedBox(height: 16),

        if (_commands.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text(
                'No custom commands yet.\nTap the + button to create one!',
                style: TextStyle(color: Colors.white54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._commands.values.map((command) => _buildCommandCard(command)).toList(),
      ],
    );
  }

  Widget _buildCommandCard(CommandConfig command) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.gesture, color: Colors.purple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sequence: ${command.sequence}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Type: ${command.type}',
                  style: const TextStyle(color: Colors.purple, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editCommand(command),
            icon: const Icon(Icons.edit, color: Colors.blue),
          ),
          IconButton(
            onPressed: () => _deleteCommand(command.id),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _editCommand(CommandConfig command) {
    // Implementation for editing commands
    _showAddCustomCommandDialog(editCommand: command);
  }

  void _deleteCommand(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Command', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this custom command?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _commands.remove(id);
              });
              await _saveCommands();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomCommandDialog({CommandConfig? editCommand}) {
    final nameController = TextEditingController(text: editCommand?.name ?? '');
    final sequenceController = TextEditingController(text: editCommand?.sequence ?? '');
    String selectedType = editCommand?.type ?? 'url';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          editCommand != null ? 'Edit Command' : 'Add Custom Command',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Command Name',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sequenceController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Hand Sign Sequence',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: '00001 → 01000',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Command Type',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: const [
                  DropdownMenuItem(value: 'url', child: Text('Open URL')),
                  DropdownMenuItem(value: 'app', child: Text('Open App')),
                  DropdownMenuItem(value: 'call', child: Text('Make Call')),
                ],
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final command = CommandConfig(
                id: editCommand?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                sequence: sequenceController.text.trim(),
                type: selectedType,
              );

              setState(() {
                _commands[command.id] = command;
              });

              await _saveCommands();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: Text(editCommand != null ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class CommandConfig {
  final String id;
  final String name;
  final String sequence;
  final String type;

  CommandConfig({
    required this.id,
    required this.name,
    required this.sequence,
    required this.type,
  });

  factory CommandConfig.fromJson(Map<String, dynamic> json) => CommandConfig(
    id: json['id'],
    name: json['name'],
    sequence: json['sequence'],
    type: json['type'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sequence': sequence,
    'type': type,
  };
}