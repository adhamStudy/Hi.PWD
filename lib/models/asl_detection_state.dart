import 'package:equatable/equatable.dart';

abstract class ASLDetectionState extends Equatable {
  const ASLDetectionState();

  @override
  List<Object?> get props => [];
}

class ASLDetectionInitial extends ASLDetectionState {}

class ASLDetectionLoading extends ASLDetectionState {}

class ASLDetectionConnected extends ASLDetectionState {
  final String connectionStatus;

  const ASLDetectionConnected({required this.connectionStatus});

  @override
  List<Object?> get props => [connectionStatus];
}

class ASLDetectionUpdated extends ASLDetectionState {
  final String currentSign;
  final List<String> sequenceBuffer;
  final String? lastAction;
  final double movement;
  final bool isStable;
  final String connectionStatus;
  final bool shouldVibrate;

  const ASLDetectionUpdated({
    required this.currentSign,
    required this.sequenceBuffer,
    this.lastAction,
    required this.movement,
    required this.isStable,
    required this.connectionStatus,
    this.shouldVibrate = false,
  });

  @override
  List<Object?> get props => [
    currentSign,
    sequenceBuffer,
    lastAction,
    movement,
    isStable,
    connectionStatus,
    shouldVibrate,
  ];
}

class ASLDetectionError extends ASLDetectionState {
  final String error;

  const ASLDetectionError({required this.error});

  @override
  List<Object?> get props => [error];
}