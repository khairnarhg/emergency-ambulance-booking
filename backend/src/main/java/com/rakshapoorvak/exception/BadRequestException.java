package com.rakshapoorvak.exception;

/**
 * Thrown when request is invalid or violates business rules.
 */
public class BadRequestException extends RuntimeException {

    public BadRequestException(String message) {
        super(message);
    }

    public BadRequestException(String message, Throwable cause) {
        super(message, cause);
    }
}
