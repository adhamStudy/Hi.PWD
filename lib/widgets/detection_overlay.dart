import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/asl_detection_cubit.dart';
import '../models/asl_detection_state.dart';

class DetectionOverlay extends StatefulWidget {
  const DetectionOverlay({Key? key}) : super(key: key);

  @override
  State<DetectionOverlay> createState() => _DetectionOverlayState();
}

class _DetectionOverlayState extends State<DetectionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _actionController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _actionAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _actionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _actionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _actionController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  String _getFingerName(int index) {
    switch (index) {
      case 0: return 'T'; // Thumb (always disabled)
      case 1: return 'I'; // Index
      case 2: return 'M'; // Middle
      case 3: return 'R'; // Ring
      case 4: return 'P'; // Pinky
      default: return '';
    }
  }

  Color _getFingerColor(int index, bool isUp) {
    if (index == 0) return Colors.grey; // Thumb always disabled
    if (!isUp) return Colors.grey[700]!;

    switch (index) {
      case 1: return Colors.blue;    // Index
      case 2: return Colors.green;   // Middle
      case 3: return Colors.orange;  // Ring
      case 4: return Colors.purple;  // Pinky
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ASLDetectionCubit, ASLDetectionState>(
      listener: (context, state) {
        if (state is ASLDetectionUpdated && state.lastAction != null) {
          _actionController.forward().then((_) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _actionController.reverse();
              }
            });
          });
        }
      },
      child: BlocBuilder<ASLDetectionCubit, ASLDetectionState>(
        builder: (context, state) {
          if (state is! ASLDetectionUpdated) {
            return _buildConnectionStatus(state);
          }

          return Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildMainDetectionCard(state),
                const SizedBox(height: 12),
                if (state.sequenceBuffer.isNotEmpty) _buildSequenceCard(state),
                const SizedBox(height: 12),
                if (state.lastAction != null) _buildActionCard(state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(ASLDetectionState state) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (state is ASLDetectionLoading) {
      statusText = 'Connecting to server...';
      statusColor = Colors.orange;
      statusIcon = Icons.wifi_find;
    } else if (state is ASLDetectionError) {
      statusText = 'Connection failed';
      statusColor = Colors.red;
      statusIcon = Icons.wifi_off;
    } else {
      statusText = 'Initializing...';
      statusColor = Colors.blue;
      statusIcon = Icons.settings;
    }

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(statusIcon, color: statusColor, size: 48),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (state is ASLDetectionError) ...[
              const SizedBox(height: 8),
              Text(
                'Check server connection',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainDetectionCard(ASLDetectionUpdated state) {
    final borderColor = state.isStable ? Colors.green : Colors.orange;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: state.isStable ? 1.0 : _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(state),
                const SizedBox(height: 16),
                _buildFingerDisplay(state),
                const SizedBox(height: 16),
                _buildMovementIndicator(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ASLDetectionUpdated state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hand Detection',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sign: ${state.currentSign}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: state.isStable ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.isStable ? Icons.check_circle : Icons.motion_photos_on,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                state.isStable ? 'STABLE' : 'MOVING',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFingerDisplay(ASLDetectionUpdated state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Finger Position',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final isUp = state.currentSign[index] == '1';
              final isThumb = index == 0;
              final fingerColor = _getFingerColor(index, isUp);

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 45,
                    height: 70,
                    decoration: BoxDecoration(
                      color: fingerColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: isUp && !isThumb ? 2 : 1,
                      ),
                      boxShadow: isUp && !isThumb ? [
                        BoxShadow(
                          color: fingerColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isUp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 24,
                        ),
                        if (isThumb)
                          const Icon(
                            Icons.block,
                            color: Colors.white54,
                            size: 12,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFingerName(index),
                    style: TextStyle(
                      color: isThumb ? Colors.white54 : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isThumb)
                    const Text(
                      'OFF',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 8,
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementIndicator(ASLDetectionUpdated state) {
    final movementPercentage = (state.movement * 100).clamp(0, 100);
    final isLowMovement = state.movement < 0.15;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Movement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${movementPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isLowMovement ? Colors.green : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: movementPercentage / 100,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(
              isLowMovement ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceCard(ASLDetectionUpdated state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gesture, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Sequence Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.sequenceBuffer.length}/3',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            children: state.sequenceBuffer.asMap().entries.map((entry) {
              final index = entry.key;
              final sign = entry.value;

              return Container(
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}. $sign',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(ASLDetectionUpdated state) {
    return AnimatedBuilder(
      animation: _actionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _actionAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Action Executed!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.lastAction!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<ASLDetectionCubit, ASLDetectionState>(
                  builder: (context, state) {
                    final cubit = context.read<ASLDetectionCubit>();
                    return Icon(
                      cubit.isVibrationEnabled ? Icons.vibration : Icons.phone_android,
                      color: Colors.white,
                      size: 20,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}