import 'package:flutter/material.dart';
import 'resource_demo_state.dart';
import 'services/users_service.dart';

/// Receives a reusable service; owns only its screen's resource notifier.
class ResourceDemo extends StatefulWidget {
  const ResourceDemo({required this.users, super.key});
  final UsersService users;

  @override
  State<ResourceDemo> createState() => ResourceDemoState();
}
