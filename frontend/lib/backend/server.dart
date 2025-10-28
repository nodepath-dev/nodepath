import '../services/arri_client.rpc.dart';

final server = ArriClient(
  baseUrl: 'http://appforgestudio.in:5000',
  onError: (error) {
    print('ARRI Client Error: $error');
  },
);
