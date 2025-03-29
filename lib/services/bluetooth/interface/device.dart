/// Represents a discovered Bluetooth device.
class BluetoothDevice {
  final String id; // 通常はMACアドレスまたはプラットフォーム固有ID
  final String name;
  // remoteId を保持 (Windows実装ではこれがMACアドレスになる)
  final String remoteId;

  BluetoothDevice({required this.id, required this.name, required this.remoteId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BluetoothDevice{id: $id, name: $name, remoteId: $remoteId}';
  }
}