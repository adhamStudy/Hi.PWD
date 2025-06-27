import 'package:flutter/material.dart';

class CommandList extends StatelessWidget {
  final ScrollController scrollController;

  const CommandList({Key? key, required this.scrollController}) : super(key: key);

  final Map<String, String> twoSignCommands = const {
    '00001 → 01111': 'Call Dad',
    '00001 → 01110': 'Call Mom',
    '01000 → 00111': 'Open Google',
    '01000 → 01111': 'Open Siri',
  };

  final Map<String, String> threeSignCommands = const {
    '00001 → 01000 → 01100': 'Call Police',
    '01000 → 00010 → 00001': 'Send Message',
    '01100 → 00001 → 01000': 'Open Camera',
    '00010 → 01000 → 01110': 'Play Music',
    '00001 → 00010 → 01100': 'Take Screenshot',
    '01000 → 01100 → 00001': 'Open Calculator',
  };

  Widget _buildSignImage(String signCode) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.asset(
          'images/signs/$signCode.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              alignment: Alignment.center,
              child: Text(
                signCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSignSequence(String sequence) {
    final signs = sequence.split(' → ');
    return Row(
      children: [
        for (int i = 0; i < signs.length; i++) ...[
          _buildSignImage(signs[i]),
          if (i < signs.length - 1) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward,
              color: Colors.blue,
              size: 16,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ],
    );
  }

  Widget _buildCommandItem(String sequence, String action, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSignSequence(sequence),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.play_arrow,
                color: accentColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              action,
              style: TextStyle(
                color: accentColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Title
        const Text(
          'Available Commands',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Perform these sign sequences to execute commands',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),

        // 2-Sign Commands Section
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '2-Sign Commands (Quick)',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ...twoSignCommands.entries.map((entry) =>
            _buildCommandItem(entry.key, entry.value, Colors.blue)
        ),

        const SizedBox(height: 32),

        // 3-Sign Commands Section
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '3-Sign Commands (Advanced)',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ...threeSignCommands.entries.map((entry) =>
            _buildCommandItem(entry.key, entry.value, Colors.orange)
        ),

        const SizedBox(height: 32),

        // Legend
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.yellow.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.yellow, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'How to Use',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '• Hold each sign steady until you feel a small vibration\n'
                    '• Wait briefly between signs\n'
                    '• Green border means stable detection\n'
                    '• Orange border means hand is moving\n'
                    '• Complete sequence triggers action vibration',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: Thumb is always down (disabled for better accuracy)',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}