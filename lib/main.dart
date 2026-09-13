import 'package:flutter/material.dart';
import 'data/connection.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'services/tournament_service.dart';
import 'ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    SimplePoolsApp(
      service: TournamentService(
        DriftTournamentRepository(AppDatabase(openConnection())),
      ),
    ),
  );
}
