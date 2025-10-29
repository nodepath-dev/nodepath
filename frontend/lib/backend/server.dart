import '../services/arri_client.rpc.dart';

final server = ArriClient(
  baseUrl: 'http://192.168.1.5:5000',
  onError: (error) {
    print('ARRI Client Error: $error');
  },
);
