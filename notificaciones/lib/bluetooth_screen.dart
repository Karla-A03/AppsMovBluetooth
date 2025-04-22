import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  List<String> _receivedDataList = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    setState(() {
      _devices.clear();
      _isScanning = true;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!_devices.contains(r.device)) {
          setState(() {
            _devices.add(r.device);
          });
        }
      }
    });

    await Future.delayed(const Duration(seconds: 6));
    await FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    await device.connect();
    print("Conectado a: ${device.name}");

    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.read) {
          var value = await characteristic.read();
          setState(() {
            _receivedDataList.add(
                'Lectura (${characteristic.uuid}): ${String.fromCharCodes(value)}');
          });
        }

        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            setState(() {
              _receivedDataList.add(
                  'Notificación (${characteristic.uuid}): ${String.fromCharCodes(value)}');
            });
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth BLE'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_devices[index].name.isNotEmpty
                      ? _devices[index].name
                      : _devices[index].id.toString()),
                  subtitle: Text(_devices[index].id.toString()),
                  onTap: () => _connectToDevice(_devices[index]),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: _receivedDataList.isEmpty
                ? const Center(child: Text("No hay datos recibidos."))
                : ListView.builder(
              itemCount: _receivedDataList.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(_receivedDataList[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
