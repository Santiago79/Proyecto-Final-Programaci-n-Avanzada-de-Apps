import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routes/app_router.dart';

final routerProvider = Provider((ref) => appRouter);