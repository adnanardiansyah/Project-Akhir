// Setelah 10 detik, UI memberi tahu bahwa server belum mengonfirmasi penulisan.
const Duration writePendingNoticeDelay = Duration(seconds: 10);

// Future penulisan hanya selesai setelah server mengonfirmasi atau menolak write.
Future<void> waitForServerAck(Future<void> write) => write;
