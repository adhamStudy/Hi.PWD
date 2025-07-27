import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/asl_detection_cubit.dart';
import '../models/asl_detection_state.dart';

class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ASLDetectionCubit, ASLDetectionState>(
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
    );
  }

  Widget _buildConnectionStatus(ASLDetectionState state) {
    String statusText;
    IconData statusIcon;
    Color iconColor;

    if (state is ASLDetectionLoading) {
      statusText = 'Connecting to server...';
      statusIcon = Icons.wifi_find;
      iconColor = Colors.orange;
    } else if (state is ASLDetectionError) {
      statusText = 'Connection failed';
      statusIcon = Icons.wifi_off;
      iconColor = Colors.red;
    } else {
      statusText = 'Initializing...';
      statusIcon = Icons.settings;
      iconColor = Colors.blue;
    }

    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(statusIcon, color: iconColor, size: 32),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDetectionCard(ASLDetectionUpdated state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.isStable ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
    );
  }

  Widget _buildHeader(ASLDetectionUpdated state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hand Detection',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sign: ${state.currentSign}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: state.isStable ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: state.isStable ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: state.isStable ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                state.isStable ? 'STABLE' : 'MOVING',
                style: TextStyle(
                  color: state.isStable ? Colors.green.shade700 : Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'Finger Position',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final isUp = state.currentSign[index] == '1';
              final isThumb = index == 0;

              return Column(
                children: [
                  Container(
                    width: 45,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isThumb
                          ? Colors.grey.withOpacity(0.1)
                          : isUp
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isThumb
                            ? Colors.grey.withOpacity(0.3)
                            : isUp
                            ? Colors.blue.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isUp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: isThumb
                              ? Colors.grey
                              : isUp
                              ? Colors.blue.shade600
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                        if (isThumb)
                          Icon(
                            Icons.block,
                            color: Colors.grey,
                            size: 12,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFingerName(index),
                    style: TextStyle(
                      color: isThumb ? Colors.grey : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isThumb)
                    Text(
                      'OFF',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Movement',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${movementPercentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: movementPercentage / 100,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.blue.shade600,
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
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gesture, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Sequence Progress',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  '${state.sequenceBuffer.length}/3',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  '${index + 1}. $sign',
                  style: const TextStyle(
                    color: Colors.black87,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Action Executed',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.lastAction!,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                color: cubit.isVibrationEnabled ? Colors.blue.shade600 : Colors.grey.shade600,
                size: 18,
              );
            },
          ),
        ],
      ),
    );
  }
}