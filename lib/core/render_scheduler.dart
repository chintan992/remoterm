import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:xterm/xterm.dart';

/// A scheduler that buffers terminal output and applies it in batches
/// to the [Terminal] instance to ensure the UI thread remains responsive
/// during high-throughput AI output streams.
class RenderScheduler {
  final Terminal terminal;
  final List<String> _buffer = [];
  bool _isScheduled = false;

  RenderScheduler(this.terminal);

  /// Adds data to the render buffer.
  void feed(String data) {
    _buffer.add(data);
    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_isScheduled || _buffer.isEmpty) return;

    _isScheduled = true;
    
    // Schedule the flush to happen before the next frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _flush();
    });
  }

  void _flush() {
    if (_buffer.isEmpty) {
      _isScheduled = false;
      return;
    }

    // Combine all buffered strings and write them at once to minimize
    // the number of terminal engine cycles per frame.
    final data = _buffer.join();
    _buffer.clear();
    
    terminal.write(data);
    
    _isScheduled = false;
    
    // If more data arrived during the write, schedule another flush
    if (_buffer.isNotEmpty) {
      _scheduleFlush();
    }
  }

  /// Immediately flushes the buffer. Useful for ensuring keystroke
  /// feedback is rendered without waiting for the next frame.
  void flushNow() {
    if (_buffer.isNotEmpty) {
      _flush();
    }
  }
}
