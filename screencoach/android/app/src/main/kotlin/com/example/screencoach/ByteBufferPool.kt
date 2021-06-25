package com.example.screencoach

import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentLinkedQueue

object ByteBufferPool {
    private const val BUFFER_SIZE = 16384 // XXX: Is this ideal?
    private val pool = ConcurrentLinkedQueue<ByteBuffer>()
    fun acquire(): ByteBuffer? {
        var buffer = pool.poll()
        if (buffer == null) buffer =
            ByteBuffer.allocateDirect(BUFFER_SIZE) // Using DirectBuffer for zero-copy
        return buffer
    }

    fun release(buffer: ByteBuffer) {
        buffer.clear()
        pool.offer(buffer)
    }

    fun clear() {
        pool.clear()
    }
}