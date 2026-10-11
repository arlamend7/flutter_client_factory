# Flutter resource example

From this folder run `flutter pub get`, then generate a local runner with
`flutter create --platforms=web .` and use `flutter run -d chrome`. Platform runner
files are intentionally not bundled. The example uses a cancellable simulated read
so it works offline; replace the loader with `client.send` for real HTTP.

Repeated refreshes cancel the previous read and prevent old results overwriting
new state. The widget disposes its notifier/resource when removed. Each widget and
state type has its own file. This example is not a claim that Flutter web was
executed during the core's browser transport tests.
