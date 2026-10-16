# IQRA: this copy of flutter_local_notifications_windows builds no native code (it needs the ATL
# component of Visual Studio). Windows reminders are shown by IQRA itself; see lib/core/notify.dart.
cmake_minimum_required(VERSION 3.14)
project(flutter_local_notifications_windows LANGUAGES CXX)
add_library(flutter_local_notifications_windows INTERFACE)
set(flutter_local_notifications_windows_bundled_libraries "" PARENT_SCOPE)
