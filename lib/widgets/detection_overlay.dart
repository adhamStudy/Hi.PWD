import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/asl_detection_cubit.dart';
import '../models/asl_detection_state.dart';

class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({Key? key}) : super(key: key);

  String _getFingerName(int index) {
    switch (index) {
      case 0: return 'T';
      case 1: return 'I';
      case 2: return 'M';
      case 3: return 'R';
      case 4: return 'P';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ASLDetectionCubit, ASLDetectionState>(
      builder: (context, state) {
        if (state is! ASLDetectionUpdated) {
          return Container();
        }

        return Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isStable ? Colors.green : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Current Sign: ${state.currentSign}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        BlocBuilder<ASLDetectionCubit, ASLDetectionState>(
                          builder: (context, state) {
                            final cubit = context.read<ASLDetectionCubit>();
                            return Icon(
                              cubit.isVibrationEnabled ? Icons.vibration : Icons.phone_android,
                              color: cubit.isVibrationEnabled ? Colors.blue : Colors.grey,
                              size: 16,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final isUp = state.currentSign[index] == '1';
                        return Container(
                          width: 40,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isUp ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isUp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 20,
                              ),
                              Text(
                                _getFingerName(index),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Text(
                          'Movement: ${state.movement.toStringAsFixed(3)}',
                          style: TextStyle(
                            color: state.movement < 0.15 ? Colors.green : Colors.red,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: state.isStable ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            state.isStable ? 'STABLE' : 'MOVING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (state.sequenceBuffer.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sequence Buffer:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.sequenceBuffer.join(' → '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              if (state.lastAction != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: state.shouldVibrate ? Colors.yellow.withOpacity(0.9) : Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.shouldVibrate ? Icons.vibration : Icons.check_circle,
                        color: state.shouldVibrate ? Colors.black : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Action: ${state.lastAction}',
                          style: TextStyle(
                            color: state.shouldVibrate ? Colors.black : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}