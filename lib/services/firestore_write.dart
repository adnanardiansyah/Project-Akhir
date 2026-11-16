// Batas tunggu konfirmasi server; setelahnya Firestore tetap mengirim saat kembali online
const Duration writeAckTimeout = Duration(seconds: 10);

// Menunggu tulisan Firestore paling lama writeAckTimeout agar tampilan tidak terkunci saat offline
Future<void> awaitWrite(Future<void> write) =>
    write.timeout(writeAckTimeout, onTimeout: () {});
