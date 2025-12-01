import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';

import '../cubit/sensor_data_cubit.dart';
import '../cubit/sensor_data_state.dart';

import 'temp_humidity_card.dart';
import 'amonia_chart.dart';
import 'sensor_error.dart';

class SensorCard extends StatelessWidget {
  const SensorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SensorDataCubit(
        apiService: context.read<ApiService>(),
        storageService: context.read<StorageService>(),
      ),
      child: Card(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<SensorDataCubit, SensorDataState>(
            builder: (context, state) {

              if (state is SensorDataLoading || state is SensorDataInitial) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (state is SensorDataError) {
                return SensorErrorWidget(
                  message: "${state.message}\nPastikan ID perangkat Anda benar.",
                  onRetry: () => context.read<SensorDataCubit>().fetchSensorData(),
                );
              }

              if (state is SensorDataLoaded) {
                final List<dynamic> sensorDataList = state.sensorDataList;
                final Map<String, dynamic> latestData = sensorDataList.isNotEmpty
                    ? sensorDataList.first as Map<String, dynamic>? ?? {}
                    : {};

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monitoring Sensor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TempHumidityCard(sensorData: latestData),
                    const SizedBox(height: 16),
                    AmmoniaChart(sensorData: sensorDataList),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}